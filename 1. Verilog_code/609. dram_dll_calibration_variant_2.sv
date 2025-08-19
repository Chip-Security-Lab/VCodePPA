//SystemVerilog
module dram_dll_calibration #(
    parameter CAL_CYCLES = 128
)(
    input clk,
    input calibrate,
    output reg dll_locked
);
    reg [15:0] cal_counter;
    
    // Kogge-Stone adder signals
    wire [15:0] g, p;
    wire [15:0] g_stage1, p_stage1;
    wire [15:0] g_stage2, p_stage2;
    wire [15:0] g_stage3, p_stage3;
    wire [15:0] g_stage4, p_stage4;
    wire [15:0] sum;
    
    // Generate and Propagate
    assign g = cal_counter & 16'h0001;
    assign p = cal_counter ^ 16'h0001;
    
    // Stage 1
    assign g_stage1[0] = g[0];
    assign p_stage1[0] = p[0];
    assign g_stage1[1] = g[1] | (p[1] & g[0]);
    assign p_stage1[1] = p[1] & p[0];
    assign g_stage1[2] = g[2] | (p[2] & g[1]);
    assign p_stage1[2] = p[2] & p[1];
    assign g_stage1[3] = g[3] | (p[3] & g[2]);
    assign p_stage1[3] = p[3] & p[2];
    assign g_stage1[4] = g[4] | (p[4] & g[3]);
    assign p_stage1[4] = p[4] & p[3];
    assign g_stage1[5] = g[5] | (p[5] & g[4]);
    assign p_stage1[5] = p[5] & p[4];
    assign g_stage1[6] = g[6] | (p[6] & g[5]);
    assign p_stage1[6] = p[6] & p[5];
    assign g_stage1[7] = g[7] | (p[7] & g[6]);
    assign p_stage1[7] = p[7] & p[6];
    assign g_stage1[8] = g[8] | (p[8] & g[7]);
    assign p_stage1[8] = p[8] & p[7];
    assign g_stage1[9] = g[9] | (p[9] & g[8]);
    assign p_stage1[9] = p[9] & p[8];
    assign g_stage1[10] = g[10] | (p[10] & g[9]);
    assign p_stage1[10] = p[10] & p[9];
    assign g_stage1[11] = g[11] | (p[11] & g[10]);
    assign p_stage1[11] = p[11] & p[10];
    assign g_stage1[12] = g[12] | (p[12] & g[11]);
    assign p_stage1[12] = p[12] & p[11];
    assign g_stage1[13] = g[13] | (p[13] & g[12]);
    assign p_stage1[13] = p[13] & p[12];
    assign g_stage1[14] = g[14] | (p[14] & g[13]);
    assign p_stage1[14] = p[14] & p[13];
    assign g_stage1[15] = g[15] | (p[15] & g[14]);
    assign p_stage1[15] = p[15] & p[14];
    
    // Stage 2
    assign g_stage2[1:0] = g_stage1[1:0];
    assign p_stage2[1:0] = p_stage1[1:0];
    assign g_stage2[2] = g_stage1[2] | (p_stage1[2] & g_stage1[0]);
    assign p_stage2[2] = p_stage1[2] & p_stage1[0];
    assign g_stage2[3] = g_stage1[3] | (p_stage1[3] & g_stage1[1]);
    assign p_stage2[3] = p_stage1[3] & p_stage1[1];
    assign g_stage2[4] = g_stage1[4] | (p_stage1[4] & g_stage1[2]);
    assign p_stage2[4] = p_stage1[4] & p_stage1[2];
    assign g_stage2[5] = g_stage1[5] | (p_stage1[5] & g_stage1[3]);
    assign p_stage2[5] = p_stage1[5] & p_stage1[3];
    assign g_stage2[6] = g_stage1[6] | (p_stage1[6] & g_stage1[4]);
    assign p_stage2[6] = p_stage1[6] & p_stage1[4];
    assign g_stage2[7] = g_stage1[7] | (p_stage1[7] & g_stage1[5]);
    assign p_stage2[7] = p_stage1[7] & p_stage1[5];
    assign g_stage2[8] = g_stage1[8] | (p_stage1[8] & g_stage1[6]);
    assign p_stage2[8] = p_stage1[8] & p_stage1[6];
    assign g_stage2[9] = g_stage1[9] | (p_stage1[9] & g_stage1[7]);
    assign p_stage2[9] = p_stage1[9] & p_stage1[7];
    assign g_stage2[10] = g_stage1[10] | (p_stage1[10] & g_stage1[8]);
    assign p_stage2[10] = p_stage1[10] & p_stage1[8];
    assign g_stage2[11] = g_stage1[11] | (p_stage1[11] & g_stage1[9]);
    assign p_stage2[11] = p_stage1[11] & p_stage1[9];
    assign g_stage2[12] = g_stage1[12] | (p_stage1[12] & g_stage1[10]);
    assign p_stage2[12] = p_stage1[12] & p_stage1[10];
    assign g_stage2[13] = g_stage1[13] | (p_stage1[13] & g_stage1[11]);
    assign p_stage2[13] = p_stage1[13] & p_stage1[11];
    assign g_stage2[14] = g_stage1[14] | (p_stage1[14] & g_stage1[12]);
    assign p_stage2[14] = p_stage1[14] & p_stage1[12];
    assign g_stage2[15] = g_stage1[15] | (p_stage1[15] & g_stage1[13]);
    assign p_stage2[15] = p_stage1[15] & p_stage1[13];
    
    // Stage 3
    assign g_stage3[3:0] = g_stage2[3:0];
    assign p_stage3[3:0] = p_stage2[3:0];
    assign g_stage3[4] = g_stage2[4] | (p_stage2[4] & g_stage2[0]);
    assign p_stage3[4] = p_stage2[4] & p_stage2[0];
    assign g_stage3[5] = g_stage2[5] | (p_stage2[5] & g_stage2[1]);
    assign p_stage3[5] = p_stage2[5] & p_stage2[1];
    assign g_stage3[6] = g_stage2[6] | (p_stage2[6] & g_stage2[2]);
    assign p_stage3[6] = p_stage2[6] & p_stage2[2];
    assign g_stage3[7] = g_stage2[7] | (p_stage2[7] & g_stage2[3]);
    assign p_stage3[7] = p_stage2[7] & p_stage2[3];
    assign g_stage3[8] = g_stage2[8] | (p_stage2[8] & g_stage2[4]);
    assign p_stage3[8] = p_stage2[8] & p_stage2[4];
    assign g_stage3[9] = g_stage2[9] | (p_stage2[9] & g_stage2[5]);
    assign p_stage3[9] = p_stage2[9] & p_stage2[5];
    assign g_stage3[10] = g_stage2[10] | (p_stage2[10] & g_stage2[6]);
    assign p_stage3[10] = p_stage2[10] & p_stage2[6];
    assign g_stage3[11] = g_stage2[11] | (p_stage2[11] & g_stage2[7]);
    assign p_stage3[11] = p_stage2[11] & p_stage2[7];
    assign g_stage3[12] = g_stage2[12] | (p_stage2[12] & g_stage2[8]);
    assign p_stage3[12] = p_stage2[12] & p_stage2[8];
    assign g_stage3[13] = g_stage2[13] | (p_stage2[13] & g_stage2[9]);
    assign p_stage3[13] = p_stage2[13] & p_stage2[9];
    assign g_stage3[14] = g_stage2[14] | (p_stage2[14] & g_stage2[10]);
    assign p_stage3[14] = p_stage2[14] & p_stage2[10];
    assign g_stage3[15] = g_stage2[15] | (p_stage2[15] & g_stage2[11]);
    assign p_stage3[15] = p_stage2[15] & p_stage2[11];
    
    // Stage 4
    assign g_stage4[7:0] = g_stage3[7:0];
    assign p_stage4[7:0] = p_stage3[7:0];
    assign g_stage4[8] = g_stage3[8] | (p_stage3[8] & g_stage3[0]);
    assign p_stage4[8] = p_stage3[8] & p_stage3[0];
    assign g_stage4[9] = g_stage3[9] | (p_stage3[9] & g_stage3[1]);
    assign p_stage4[9] = p_stage3[9] & p_stage3[1];
    assign g_stage4[10] = g_stage3[10] | (p_stage3[10] & g_stage3[2]);
    assign p_stage4[10] = p_stage3[10] & p_stage3[2];
    assign g_stage4[11] = g_stage3[11] | (p_stage3[11] & g_stage3[3]);
    assign p_stage4[11] = p_stage3[11] & p_stage3[3];
    assign g_stage4[12] = g_stage3[12] | (p_stage3[12] & g_stage3[4]);
    assign p_stage4[12] = p_stage3[12] & p_stage3[4];
    assign g_stage4[13] = g_stage3[13] | (p_stage3[13] & g_stage3[5]);
    assign p_stage4[13] = p_stage3[13] & p_stage3[5];
    assign g_stage4[14] = g_stage3[14] | (p_stage3[14] & g_stage3[6]);
    assign p_stage4[14] = p_stage3[14] & p_stage3[6];
    assign g_stage4[15] = g_stage3[15] | (p_stage3[15] & g_stage3[7]);
    assign p_stage4[15] = p_stage3[15] & p_stage3[7];
    
    // Final sum calculation
    assign sum[0] = p[0];
    assign sum[1] = p[1] ^ g_stage4[0];
    assign sum[2] = p[2] ^ g_stage4[1];
    assign sum[3] = p[3] ^ g_stage4[2];
    assign sum[4] = p[4] ^ g_stage4[3];
    assign sum[5] = p[5] ^ g_stage4[4];
    assign sum[6] = p[6] ^ g_stage4[5];
    assign sum[7] = p[7] ^ g_stage4[6];
    assign sum[8] = p[8] ^ g_stage4[7];
    assign sum[9] = p[9] ^ g_stage4[8];
    assign sum[10] = p[10] ^ g_stage4[9];
    assign sum[11] = p[11] ^ g_stage4[10];
    assign sum[12] = p[12] ^ g_stage4[11];
    assign sum[13] = p[13] ^ g_stage4[12];
    assign sum[14] = p[14] ^ g_stage4[13];
    assign sum[15] = p[15] ^ g_stage4[14];
    
    always @(posedge clk) begin
        if(calibrate) begin
            cal_counter <= sum;
            dll_locked <= (cal_counter == CAL_CYCLES);
        end else begin
            cal_counter <= 0;
            dll_locked <= 0;
        end
    end
endmodule