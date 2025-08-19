//SystemVerilog
module crc_config_xor #(
    parameter WIDTH = 16,
    parameter INIT = 16'hFFFF,
    parameter FINAL_XOR = 16'h0000
)(
    input clk, en, rst_n,
    input valid_in,
    input [WIDTH-1:0] data,
    output reg [WIDTH-1:0] crc,
    output reg valid_out,
    output [WIDTH-1:0] crc_result
);

// Pipeline Stage 1 - Calculate poly_mask and data_xor
reg [WIDTH-1:0] poly_mask_stage1;
reg [WIDTH-1:0] data_xor_stage1;
reg [WIDTH-1:0] crc_shift_stage1;
reg [WIDTH-1:0] data_stage1;
reg [WIDTH-1:0] crc_stage1;
reg valid_stage1;

// Pipeline Stage 2 - Calculate crc_next
reg [WIDTH-1:0] crc_next_stage2;
reg valid_stage2;

// Stage 1 - Combinational logic
always @(*) begin
    poly_mask_stage1 = crc[WIDTH-1] ? 16'h1021 : 16'h0000;
    data_xor_stage1 = data ^ poly_mask_stage1;
    crc_shift_stage1 = {crc[WIDTH-2:0], 1'b0};
end

// Stage 1 - Register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_stage1 <= {WIDTH{1'b0}};
        crc_stage1 <= {WIDTH{1'b0}};
        crc_shift_stage1 <= {WIDTH{1'b0}};
        data_xor_stage1 <= {WIDTH{1'b0}};
        valid_stage1 <= 1'b0;
    end else begin
        if (en) begin
            data_stage1 <= data;
            crc_stage1 <= crc;
            crc_shift_stage1 <= crc_shift_stage1;
            data_xor_stage1 <= data_xor_stage1;
            valid_stage1 <= valid_in;
        end
    end
end

// Stage 2 - Combinational logic
always @(*) begin
    crc_next_stage2 = crc_shift_stage1 ^ data_xor_stage1;
end

// Stage 2 - Register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        crc <= INIT;
        valid_stage2 <= 1'b0;
    end else begin
        if (en) begin
            if (valid_stage1) begin
                crc <= crc_next_stage2;
            end else begin
                crc <= INIT;
            end
            valid_stage2 <= valid_stage1;
        end
    end
end

// Output stage
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_out <= 1'b0;
    end else begin
        if (en) begin
            valid_out <= valid_stage2;
        end else begin
            valid_out <= 1'b0;
        end
    end
end

// Final XOR operation
assign crc_result = crc ^ FINAL_XOR;

endmodule