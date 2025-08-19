//SystemVerilog
module bytewise_crc16(
    input wire clk_i,
    input wire rst_i,
    input wire [7:0] data_i,
    input wire valid_i,
    output wire ready_o,
    output wire [15:0] crc_o
);
    localparam POLYNOMIAL = 16'h8005;
    
    // Stage 1 registers
    reg [15:0] lfsr_stage1;
    reg [7:0] data_stage1;
    reg valid_stage1;
    
    // Stage 2 registers
    reg [15:0] lfsr_stage2;
    reg valid_stage2;
    
    // Stage 3 registers
    reg [15:0] lfsr_stage3;
    reg valid_stage3;
    
    // Intermediate calculation signals
    wire [15:0] xor_term1 = {lfsr_stage1[7:0], 8'h00};
    wire [15:0] xor_term2 = {8{lfsr_stage1[15]}} & POLYNOMIAL;
    wire [15:0] xor_term3 = {8'h00, data_stage1};
    
    // Ready signal generation
    assign ready_o = ~valid_stage1;
    
    // CRC output
    assign crc_o = lfsr_stage3;
    
    // Pipeline Stage 1: Register input data and valid signal
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            data_stage1 <= 8'h00;
            lfsr_stage1 <= 16'hFFFF;
            valid_stage1 <= 1'b0;
        end else begin
            if (valid_i && ready_o) begin
                data_stage1 <= data_i;
                lfsr_stage1 <= (valid_stage3) ? lfsr_stage3 : lfsr_stage1;
                valid_stage1 <= 1'b1;
            end else if (valid_stage3) begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Pipeline Stage 2: First part of CRC calculation
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            lfsr_stage2 <= 16'hFFFF;
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                lfsr_stage2 <= xor_term1 ^ xor_term2;
                valid_stage2 <= 1'b1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // Pipeline Stage 3: Complete CRC calculation
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            lfsr_stage3 <= 16'hFFFF;
            valid_stage3 <= 1'b0;
        end else begin
            if (valid_stage2) begin
                lfsr_stage3 <= lfsr_stage2 ^ xor_term3;
                valid_stage3 <= 1'b1;
            end else begin
                valid_stage3 <= 1'b0;
            end
        end
    end
endmodule