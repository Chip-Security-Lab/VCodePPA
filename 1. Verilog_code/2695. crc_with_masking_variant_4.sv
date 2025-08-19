//SystemVerilog
module crc_with_masking(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire [7:0] mask,
    input wire valid,
    output reg ready,
    output reg [7:0] crc_out
);
    parameter [7:0] POLY = 8'h07;
    
    // Stage 1: Data masking and initial XOR
    reg [7:0] masked_data_stage1;
    reg [7:0] crc_stage1;
    reg valid_stage1;
    reg ready_stage1;
    
    // Stage 2: Calculate new CRC with polynomial
    reg [7:0] crc_stage2;
    reg valid_stage2;
    reg ready_stage2;
    
    // Stage 3: Final CRC computation
    reg [7:0] crc_stage3;
    reg valid_stage3;
    reg ready_stage3;
    
    // Stage 1 pipeline: Mask data and prepare initial value
    always @(posedge clk) begin
        if (rst) begin
            masked_data_stage1 <= 8'h00;
            crc_stage1 <= 8'h00;
            valid_stage1 <= 1'b0;
            ready_stage1 <= 1'b0;
        end else begin
            if (valid && ready_stage1) begin
                masked_data_stage1 <= data & mask;
                crc_stage1 <= crc_out;
                valid_stage1 <= 1'b1;
            end else if (ready_stage2) begin
                valid_stage1 <= 1'b0;
            end
            ready_stage1 <= !valid_stage1 || ready_stage2;
        end
    end
    
    // Stage 2 pipeline: Initial CRC calculation steps
    always @(posedge clk) begin
        if (rst) begin
            crc_stage2 <= 8'h00;
            valid_stage2 <= 1'b0;
            ready_stage2 <= 1'b0;
        end else begin
            if (valid_stage1 && ready_stage2) begin
                crc_stage2 <= {crc_stage1[6:0], 1'b0};
                valid_stage2 <= 1'b1;
            end else if (ready_stage3) begin
                valid_stage2 <= 1'b0;
            end
            ready_stage2 <= !valid_stage2 || ready_stage3;
        end
    end
    
    // Stage 3 pipeline: XOR with polynomial based on conditions
    always @(posedge clk) begin
        if (rst) begin
            crc_stage3 <= 8'h00;
            valid_stage3 <= 1'b0;
            ready_stage3 <= 1'b0;
        end else begin
            if (valid_stage2 && ready_stage3) begin
                crc_stage3 <= crc_stage2 ^ ((crc_stage1[7] ^ masked_data_stage1[0]) ? POLY : 8'h00);
                valid_stage3 <= 1'b1;
            end else if (ready) begin
                valid_stage3 <= 1'b0;
            end
            ready_stage3 <= !valid_stage3 || ready;
        end
    end
    
    // Output stage
    always @(posedge clk) begin
        if (rst) begin
            crc_out <= 8'h00;
            ready <= 1'b0;
        end else begin
            if (valid_stage3) begin
                crc_out <= crc_stage3;
                ready <= 1'b1;
            end else begin
                ready <= 1'b0;
            end
        end
    end
    
endmodule