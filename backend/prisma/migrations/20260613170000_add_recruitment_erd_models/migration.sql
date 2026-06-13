-- CreateEnum
CREATE TYPE "PositionStatus" AS ENUM ('DRAFT', 'OPEN', 'CLOSED', 'ON_HOLD');

-- CreateEnum
CREATE TYPE "EmploymentType" AS ENUM ('FULL_TIME', 'PART_TIME', 'CONTRACT', 'INTERNSHIP', 'TEMPORARY');

-- CreateEnum
CREATE TYPE "ApplicationStatus" AS ENUM ('PENDING', 'REVIEWING', 'INTERVIEW', 'OFFER', 'REJECTED', 'HIRED', 'WITHDRAWN');

-- CreateEnum
CREATE TYPE "InterviewResult" AS ENUM ('PENDING', 'PASSED', 'FAILED', 'NO_SHOW', 'RESCHEDULED');

-- CreateEnum
CREATE TYPE "EmployeeRole" AS ENUM ('RECRUITER', 'INTERVIEWER', 'HIRING_MANAGER', 'ADMIN');

-- Renombrar tablas existentes (preserva datos)
ALTER TABLE "Candidate" RENAME TO "candidates";
ALTER TABLE "Education" RENAME TO "educations";
ALTER TABLE "WorkExperience" RENAME TO "work_experiences";
ALTER TABLE "Resume" RENAME TO "resumes";

-- Renombrar columnas: candidates
ALTER TABLE "candidates" RENAME COLUMN "firstName" TO "first_name";
ALTER TABLE "candidates" RENAME COLUMN "lastName" TO "last_name";

-- Renombrar columnas: educations
ALTER TABLE "educations" RENAME COLUMN "startDate" TO "start_date";
ALTER TABLE "educations" RENAME COLUMN "endDate" TO "end_date";
ALTER TABLE "educations" RENAME COLUMN "candidateId" TO "candidate_id";

-- Renombrar columnas: work_experiences
ALTER TABLE "work_experiences" RENAME COLUMN "startDate" TO "start_date";
ALTER TABLE "work_experiences" RENAME COLUMN "endDate" TO "end_date";
ALTER TABLE "work_experiences" RENAME COLUMN "candidateId" TO "candidate_id";

-- Renombrar columnas: resumes
ALTER TABLE "resumes" RENAME COLUMN "filePath" TO "file_path";
ALTER TABLE "resumes" RENAME COLUMN "fileType" TO "file_type";
ALTER TABLE "resumes" RENAME COLUMN "uploadDate" TO "upload_date";
ALTER TABLE "resumes" RENAME COLUMN "candidateId" TO "candidate_id";

-- Renombrar constraints e índices existentes
ALTER INDEX "Candidate_pkey" RENAME TO "candidates_pkey";
ALTER INDEX "Candidate_email_key" RENAME TO "candidates_email_key";
ALTER INDEX "Education_pkey" RENAME TO "educations_pkey";
ALTER INDEX "WorkExperience_pkey" RENAME TO "work_experiences_pkey";
ALTER INDEX "Resume_pkey" RENAME TO "resumes_pkey";

-- Recrear FKs con ON DELETE CASCADE
ALTER TABLE "educations" DROP CONSTRAINT "Education_candidateId_fkey";
ALTER TABLE "work_experiences" DROP CONSTRAINT "WorkExperience_candidateId_fkey";
ALTER TABLE "resumes" DROP CONSTRAINT "Resume_candidateId_fkey";

ALTER TABLE "educations" ADD CONSTRAINT "educations_candidate_id_fkey" FOREIGN KEY ("candidate_id") REFERENCES "candidates"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "work_experiences" ADD CONSTRAINT "work_experiences_candidate_id_fkey" FOREIGN KEY ("candidate_id") REFERENCES "candidates"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "resumes" ADD CONSTRAINT "resumes_candidate_id_fkey" FOREIGN KEY ("candidate_id") REFERENCES "candidates"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Índices en tablas existentes
CREATE INDEX "educations_candidate_id_idx" ON "educations"("candidate_id");
CREATE INDEX "work_experiences_candidate_id_idx" ON "work_experiences"("candidate_id");
CREATE INDEX "resumes_candidate_id_idx" ON "resumes"("candidate_id");

-- CreateTable
CREATE TABLE "companies" (
    "id" SERIAL NOT NULL,
    "name" VARCHAR(200) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "companies_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "employees" (
    "id" SERIAL NOT NULL,
    "company_id" INTEGER NOT NULL,
    "name" VARCHAR(200) NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "role" "EmployeeRole" NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "employees_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "interview_flows" (
    "id" SERIAL NOT NULL,
    "description" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "interview_flows_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "interview_types" (
    "id" SERIAL NOT NULL,
    "name" VARCHAR(100) NOT NULL,
    "description" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "interview_types_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "interview_steps" (
    "id" SERIAL NOT NULL,
    "interview_flow_id" INTEGER NOT NULL,
    "interview_type_id" INTEGER NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "order_index" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "interview_steps_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "positions" (
    "id" SERIAL NOT NULL,
    "company_id" INTEGER NOT NULL,
    "interview_flow_id" INTEGER NOT NULL,
    "title" VARCHAR(200) NOT NULL,
    "description" TEXT,
    "status" "PositionStatus" NOT NULL DEFAULT 'DRAFT',
    "is_visible" BOOLEAN NOT NULL DEFAULT false,
    "location" VARCHAR(200),
    "job_description" TEXT,
    "requirements" TEXT,
    "responsibilities" TEXT,
    "salary_min" DECIMAL(12,2),
    "salary_max" DECIMAL(12,2),
    "employment_type" "EmploymentType",
    "benefits" TEXT,
    "company_description" TEXT,
    "application_deadline" DATE,
    "contact_info" VARCHAR(255),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "positions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "applications" (
    "id" SERIAL NOT NULL,
    "position_id" INTEGER NOT NULL,
    "candidate_id" INTEGER NOT NULL,
    "application_date" DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "status" "ApplicationStatus" NOT NULL DEFAULT 'PENDING',
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "applications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "interviews" (
    "id" SERIAL NOT NULL,
    "application_id" INTEGER NOT NULL,
    "interview_step_id" INTEGER NOT NULL,
    "employee_id" INTEGER NOT NULL,
    "interview_date" TIMESTAMP(3) NOT NULL,
    "result" "InterviewResult" NOT NULL DEFAULT 'PENDING',
    "score" SMALLINT,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "interviews_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "companies_name_idx" ON "companies"("name");

-- CreateIndex
CREATE INDEX "employees_company_id_idx" ON "employees"("company_id");

-- CreateIndex
CREATE INDEX "employees_is_active_idx" ON "employees"("is_active");

-- CreateIndex
CREATE UNIQUE INDEX "employees_company_id_email_key" ON "employees"("company_id", "email");

-- CreateIndex
CREATE UNIQUE INDEX "interview_types_name_key" ON "interview_types"("name");

-- CreateIndex
CREATE INDEX "interview_steps_interview_flow_id_idx" ON "interview_steps"("interview_flow_id");

-- CreateIndex
CREATE INDEX "interview_steps_interview_type_id_idx" ON "interview_steps"("interview_type_id");

-- CreateIndex
CREATE UNIQUE INDEX "interview_steps_interview_flow_id_order_index_key" ON "interview_steps"("interview_flow_id", "order_index");

-- CreateIndex
CREATE UNIQUE INDEX "positions_interview_flow_id_key" ON "positions"("interview_flow_id");

-- CreateIndex
CREATE INDEX "positions_company_id_idx" ON "positions"("company_id");

-- CreateIndex
CREATE INDEX "positions_status_idx" ON "positions"("status");

-- CreateIndex
CREATE INDEX "positions_is_visible_idx" ON "positions"("is_visible");

-- CreateIndex
CREATE INDEX "positions_application_deadline_idx" ON "positions"("application_deadline");

-- CreateIndex
CREATE INDEX "applications_position_id_idx" ON "applications"("position_id");

-- CreateIndex
CREATE INDEX "applications_candidate_id_idx" ON "applications"("candidate_id");

-- CreateIndex
CREATE INDEX "applications_status_idx" ON "applications"("status");

-- CreateIndex
CREATE INDEX "applications_application_date_idx" ON "applications"("application_date");

-- CreateIndex
CREATE UNIQUE INDEX "applications_position_id_candidate_id_key" ON "applications"("position_id", "candidate_id");

-- CreateIndex
CREATE INDEX "interviews_application_id_idx" ON "interviews"("application_id");

-- CreateIndex
CREATE INDEX "interviews_interview_step_id_idx" ON "interviews"("interview_step_id");

-- CreateIndex
CREATE INDEX "interviews_employee_id_idx" ON "interviews"("employee_id");

-- CreateIndex
CREATE INDEX "interviews_interview_date_idx" ON "interviews"("interview_date");

-- CreateIndex
CREATE INDEX "interviews_result_idx" ON "interviews"("result");

-- AddForeignKey
ALTER TABLE "employees" ADD CONSTRAINT "employees_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "interview_steps" ADD CONSTRAINT "interview_steps_interview_flow_id_fkey" FOREIGN KEY ("interview_flow_id") REFERENCES "interview_flows"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "interview_steps" ADD CONSTRAINT "interview_steps_interview_type_id_fkey" FOREIGN KEY ("interview_type_id") REFERENCES "interview_types"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "positions" ADD CONSTRAINT "positions_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "positions" ADD CONSTRAINT "positions_interview_flow_id_fkey" FOREIGN KEY ("interview_flow_id") REFERENCES "interview_flows"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "applications" ADD CONSTRAINT "applications_position_id_fkey" FOREIGN KEY ("position_id") REFERENCES "positions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "applications" ADD CONSTRAINT "applications_candidate_id_fkey" FOREIGN KEY ("candidate_id") REFERENCES "candidates"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "interviews" ADD CONSTRAINT "interviews_application_id_fkey" FOREIGN KEY ("application_id") REFERENCES "applications"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "interviews" ADD CONSTRAINT "interviews_interview_step_id_fkey" FOREIGN KEY ("interview_step_id") REFERENCES "interview_steps"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "interviews" ADD CONSTRAINT "interviews_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "employees"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
