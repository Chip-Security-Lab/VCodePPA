//SystemVerilog
module eth_fcs_gen (
    input wire clk,
    input wire rst_n,
    input wire sof,
    input wire [7:0] data,
    output reg [31:0] fcs
);

    // Pipeline registers
    reg [31:0] fcs_stage1, fcs_stage2, fcs_stage3;
    reg [7:0] data_stage1, data_stage2;
    reg sof_stage1, sof_stage2;
    
    // First pipeline stage - Data and control registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 8'h00;
            sof_stage1 <= 1'b0;
            fcs_stage1 <= 32'hFFFFFFFF;
        end else begin
            data_stage1 <= data;
            sof_stage1 <= sof;
            
            if (sof) 
                fcs_stage1 <= 32'hFFFFFFFF;
            else
                fcs_stage1 <= fcs;
        end
    end
    
    // Second pipeline stage - First part of CRC calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 8'h00;
            sof_stage2 <= 1'b0;
            fcs_stage2 <= 32'hFFFFFFFF;
        end else begin
            data_stage2 <= data_stage1;
            sof_stage2 <= sof_stage1;
            
            if (sof_stage1)
                fcs_stage2 <= 32'hFFFFFFFF;
            else begin
                // First half of CRC calculation (bits 31:16)
                fcs_stage2[31:24] <= fcs_stage1[24] ^ data_stage1[7] ^ fcs_stage1[30] ^ fcs_stage1[24];
                fcs_stage2[30:24] <= fcs_stage1[23:17];
                fcs_stage2[23] <= fcs_stage1[16] ^ data_stage1[6] ^ fcs_stage1[31] ^ fcs_stage1[23];
                fcs_stage2[22:16] <= fcs_stage1[15:9];
                fcs_stage2[15:0] <= fcs_stage1[15:0]; // Pass through for next stage
            end
        end
    end
    
    // Third pipeline stage - Second part of CRC calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fcs_stage3 <= 32'hFFFFFFFF;
        end else begin
            if (sof_stage2)
                fcs_stage3 <= 32'hFFFFFFFF;
            else begin
                // Copy over the already calculated upper bits
                fcs_stage3[31:16] <= fcs_stage2[31:16];
                
                // Calculate lower bits (15:0)
                fcs_stage3[15] <= fcs_stage2[8] ^ data_stage2[5] ^ fcs_stage2[23] ^ fcs_stage2[15];
                fcs_stage3[14:8] <= fcs_stage2[7:1];
                fcs_stage3[7] <= fcs_stage2[0] ^ data_stage2[4] ^ fcs_stage2[15] ^ fcs_stage2[7];
                fcs_stage3[6:4] <= {fcs_stage2[31], fcs_stage2[30], fcs_stage2[29]};
                fcs_stage3[3] <= fcs_stage2[28] ^ data_stage2[3] ^ fcs_stage2[7] ^ fcs_stage2[3];
                fcs_stage3[2:0] <= fcs_stage2[27:25];
            end
        end
    end
    
    // Final output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fcs <= 32'hFFFFFFFF;
        end else begin
            fcs <= fcs_stage3;
        end
    end

endmodule