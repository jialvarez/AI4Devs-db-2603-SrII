import {
  PrismaClient,
  EmployeeRole,
  PositionStatus,
  EmploymentType,
  ApplicationStatus,
  InterviewResult,
} from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Iniciando seed del flujo de reclutamiento...\n');

  // ─── Tipos de entrevista ───────────────────────────────────────────────────
  const screeningType = await prisma.interviewType.upsert({
    where: { name: 'Screening' },
    update: {},
    create: {
      name: 'Screening',
      description: 'Entrevista inicial de filtrado con el equipo de RRHH.',
    },
  });

  const technicalType = await prisma.interviewType.upsert({
    where: { name: 'Técnica' },
    update: {},
    create: {
      name: 'Técnica',
      description: 'Evaluación de competencias técnicas y resolución de casos.',
    },
  });

  const managerType = await prisma.interviewType.upsert({
    where: { name: 'Manager' },
    update: {},
    create: {
      name: 'Manager',
      description: 'Entrevista final con el hiring manager para encaje cultural.',
    },
  });

  // ─── Empresa ───────────────────────────────────────────────────────────────
  const company = await prisma.company.upsert({
    where: { id: 1 },
    update: { name: 'LTI Talent Solutions' },
    create: { name: 'LTI Talent Solutions' },
  });

  // ─── Empleados ─────────────────────────────────────────────────────────────
  const recruiter = await prisma.employee.upsert({
    where: { companyId_email: { companyId: company.id, email: 'recruiter@lti.dev' } },
    update: {},
    create: {
      companyId: company.id,
      name: 'Ana García',
      email: 'recruiter@lti.dev',
      role: EmployeeRole.RECRUITER,
      isActive: true,
    },
  });

  const interviewer = await prisma.employee.upsert({
    where: { companyId_email: { companyId: company.id, email: 'interviewer@lti.dev' } },
    update: {},
    create: {
      companyId: company.id,
      name: 'Carlos Ruiz',
      email: 'interviewer@lti.dev',
      role: EmployeeRole.INTERVIEWER,
      isActive: true,
    },
  });

  // ─── Flujo de entrevista (3 pasos ordenados) ───────────────────────────────
  let interviewFlow = await prisma.interviewFlow.findFirst({
    where: { description: 'Flujo estándar de contratación LTI' },
  });

  if (!interviewFlow) {
    interviewFlow = await prisma.interviewFlow.create({
      data: {
        description: 'Flujo estándar de contratación LTI',
        steps: {
          create: [
            {
              name: 'Screening RRHH',
              orderIndex: 1,
              interviewTypeId: screeningType.id,
            },
            {
              name: 'Entrevista Técnica',
              orderIndex: 2,
              interviewTypeId: technicalType.id,
            },
            {
              name: 'Entrevista con Manager',
              orderIndex: 3,
              interviewTypeId: managerType.id,
            },
          ],
        },
      },
    });
  }

  const steps = await prisma.interviewStep.findMany({
    where: { interviewFlowId: interviewFlow.id },
    orderBy: { orderIndex: 'asc' },
  });

  const screeningStep = steps.find((s) => s.orderIndex === 1)!;
  const technicalStep = steps.find((s) => s.orderIndex === 2)!;

  // ─── Posición ──────────────────────────────────────────────────────────────
  let position = await prisma.position.findFirst({
    where: { title: 'Senior Backend Developer' },
  });

  if (!position) {
    position = await prisma.position.create({
      data: {
        companyId: company.id,
        interviewFlowId: interviewFlow.id,
        title: 'Senior Backend Developer',
        description: 'Desarrollo de APIs y servicios con Node.js y PostgreSQL.',
        status: PositionStatus.OPEN,
        isVisible: true,
        location: 'Madrid (Híbrido)',
        jobDescription: 'Diseñar e implementar microservicios escalables.',
        requirements: '5+ años con TypeScript, Node.js, Prisma y PostgreSQL.',
        responsibilities: 'Liderar decisiones técnicas del equipo backend.',
        salaryMin: 45000,
        salaryMax: 60000,
        employmentType: EmploymentType.FULL_TIME,
        benefits: 'Seguro médico, teletrabajo flexible, formación continua.',
        companyDescription: 'LTI Talent Solutions conecta talento tech con empresas líderes.',
        applicationDeadline: new Date('2026-09-30'),
        contactInfo: 'recruiter@lti.dev',
      },
    });
  }

  // ─── Candidatos ────────────────────────────────────────────────────────────
  const candidateActive = await prisma.candidate.upsert({
    where: { email: 'laura.martinez@seed.dev' },
    update: {},
    create: {
      firstName: 'Laura',
      lastName: 'Martínez',
      email: 'laura.martinez@seed.dev',
      phone: '612345678',
      address: 'Calle Mayor 10, Madrid',
    },
  });

  const candidatePending = await prisma.candidate.upsert({
    where: { email: 'pedro.sanchez@seed.dev' },
    update: {},
    create: {
      firstName: 'Pedro',
      lastName: 'Sánchez',
      email: 'pedro.sanchez@seed.dev',
      phone: '698765432',
      address: 'Av. Diagonal 200, Barcelona',
    },
  });

  // ─── Aplicación avanzada con entrevistas ───────────────────────────────────
  const application = await prisma.application.upsert({
    where: {
      positionId_candidateId: {
        positionId: position.id,
        candidateId: candidateActive.id,
      },
    },
    update: {
      status: ApplicationStatus.INTERVIEW,
      notes: 'Candidata destacada tras superar el screening inicial.',
    },
    create: {
      positionId: position.id,
      candidateId: candidateActive.id,
      applicationDate: new Date('2026-06-01'),
      status: ApplicationStatus.INTERVIEW,
      notes: 'Candidata destacada tras superar el screening inicial.',
    },
  });

  // Screening completado (evaluado)
  await prisma.interview.upsert({
    where: { id: 1 },
    update: {},
    create: {
      applicationId: application.id,
      interviewStepId: screeningStep.id,
      employeeId: recruiter.id,
      interviewDate: new Date('2026-06-10T10:00:00'),
      result: InterviewResult.PASSED,
      score: 85,
      notes: 'Buena comunicación y alineación con la cultura de la empresa.',
    },
  });

  // Entrevista técnica agendada (paso actual)
  await prisma.interview.upsert({
    where: { id: 2 },
    update: {},
    create: {
      applicationId: application.id,
      interviewStepId: technicalStep.id,
      employeeId: interviewer.id,
      interviewDate: new Date('2026-06-20T16:30:00'),
      result: InterviewResult.PENDING,
      notes: 'Pendiente de evaluar arquitectura y experiencia con Prisma.',
    },
  });

  console.log('✅ Seed completado:\n');
  console.log(`   Empresa:           ${company.name} (id: ${company.id})`);
  console.log(`   Empleados:         ${recruiter.name}, ${interviewer.name}`);
  console.log(`   Flujo entrevista:  ${interviewFlow.description} (${steps.length} pasos)`);
  console.log(`   Posición:          ${position.title} [${position.status}]`);
  console.log(`   Candidatos:        ${candidateActive.firstName} ${candidateActive.lastName}, ${candidatePending.firstName} ${candidatePending.lastName}`);
  console.log(`   Aplicación:        id ${application.id} → estado ${application.status}`);
  console.log(`   Entrevistas:       Screening (PASSED) + Técnica (PENDING)\n`);
  console.log('💡 Para verificar en PGAdmin, ejecuta: prisma/verification-queries.sql');
  console.log('   Candidato de prueba para Consulta B: laura.martinez@seed.dev\n');
}

main()
  .catch((error) => {
    console.error('❌ Error en seed:', error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
