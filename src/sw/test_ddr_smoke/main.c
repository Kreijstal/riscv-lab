/* SPDX-License-Identifier: Apache-2.0
 * SPDX-FileCopyrightText: 2026 RVLab Contributors
 */

#include <stdint.h>
#include <stdio.h>
#include <rvlab.h>

#define DDR_TIMEOUT_POLLS 2000000u

int main(void) {
    volatile uint32_t *ddr = (volatile uint32_t *)DDR3_BASE_ADDR;
    uint32_t status;

    printf("ddr_smoke: start\n");

    status = REG32(DDR_CTRL_STATUS(0));
    printf("ddr_smoke: initial status=0x%08x\n", status);

    if (!(status & (1u << DDR_CTRL_STATUS_PRESENT_LSB))) {
        printf("ddr_smoke: DDR not present\n");
        return 1;
    }

    REG32(DDR_CTRL_CTRL(0)) |= (1u << DDR_CTRL_CTRL_RST_N_LSB);
    printf("ddr_smoke: reset deasserted\n");

    for (uint32_t i = 0; i < DDR_TIMEOUT_POLLS; i++) {
        status = REG32(DDR_CTRL_STATUS(0));
        if (status & (1u << DDR_CTRL_STATUS_CALIB_COMPLETE_LSB)) {
            printf("ddr_smoke: calibration complete after %u polls, status=0x%08x\n", i, status);

            ddr[0] = 0x12345678u;
            ddr[1] = 0xcafebeefu;
            printf("ddr_smoke: readback M0=0x%08x M1=0x%08x\n", ddr[0], ddr[1]);

            if (ddr[0] != 0x12345678u || ddr[1] != 0xcafebeefu) {
                printf("ddr_smoke: readback mismatch\n");
                return 2;
            }

            printf("ddr_smoke: pass\n");
            return 0;
        }

        if ((i & 0x1ffffu) == 0) {
            printf("ddr_smoke: polling status=0x%08x at %u\n", status, i);
        }
    }

    printf("ddr_smoke: calibration timeout, status=0x%08x\n", status);
    return 3;
}
