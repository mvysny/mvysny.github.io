---
layout: post
title: Hibernate Validator HV000030
---

UnexpectedTypeException: HV000030: No validator could be found for constraint 'javax.validation.constraints.NotBlank' validating type 'java.lang.String'.

Turns out that `NotBlank` was added in validation-api 2.0, but Hibernate Validator 5.x only supports validation-api 1.0. The solution is to upgrade to
Hibernate Validator 6.0 or higher.
