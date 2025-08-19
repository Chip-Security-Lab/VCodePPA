//SystemVerilog
module parametric_crc #(
    parameter WIDTH = 8,
    parameter POLY = 8'h9B,
    parameter INIT = {WIDTH{1'b1}}
)(
    input clk, rst_n,
    input valid_in,
    input [WIDTH-1:0] data_in,
    output reg valid_out,
    output reg [WIDTH-1:0] crc_out,
    input ready_out,
    output reg ready_in
);
    // Pipeline control signals
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Pipeline stage data registers
    reg [WIDTH-1:0] data_stage1, data_stage2, data_stage3;
    reg [WIDTH-1:0] crc_stage1, crc_stage2, crc_stage3;
    reg [WIDTH-1:0] poly_masked_stage1, poly_masked_stage2;
    reg [WIDTH-1:0] xor_result_stage2;
    
    // Pipeline stall and flow control
    wire stage1_ready, stage2_ready, stage3_ready;
    assign stage3_ready = ready_out || !valid_out;
    assign stage2_ready = stage3_ready || !valid_stage3;
    assign stage1_ready = stage2_ready || !valid_stage2;
    assign ready_in = stage1_ready;
    
    // Stage 1: Data input and initial CRC preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
            data_stage1 <= {WIDTH{1'b0}};
            crc_stage1 <= INIT;
        end else if (stage1_ready) begin
            valid_stage1 <= valid_in;
            data_stage1 <= data_in;
            crc_stage1 <= valid_out ? crc_out : INIT;
            poly_masked_stage1 <= valid_out ? (crc_out[WIDTH-1] ? POLY : {WIDTH{1'b0}}) : 
                                  (INIT[WIDTH-1] ? POLY : {WIDTH{1'b0}});
        end
    end
    
    // Stage 2: XOR operations and shift preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
            data_stage2 <= {WIDTH{1'b0}};
            crc_stage2 <= INIT;
            poly_masked_stage2 <= {WIDTH{1'b0}};
        end else if (stage2_ready) begin
            valid_stage2 <= valid_stage1;
            data_stage2 <= data_stage1;
            crc_stage2 <= crc_stage1;
            poly_masked_stage2 <= poly_masked_stage1;
            xor_result_stage2 <= data_stage1 ^ poly_masked_stage1;
        end
    end
    
    // Stage 3: Final CRC calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage3 <= 1'b0;
            crc_stage3 <= INIT;
        end else if (stage3_ready) begin
            valid_stage3 <= valid_stage2;
            crc_stage3 <= (crc_stage2 << 1) ^ xor_result_stage2;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            crc_out <= INIT;
        end else if (ready_out) begin
            valid_out <= valid_stage3;
            crc_out <= crc_stage3;
        end
    end
endmodule