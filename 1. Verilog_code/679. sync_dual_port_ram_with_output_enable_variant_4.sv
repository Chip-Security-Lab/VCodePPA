//SystemVerilog
// Memory core module with pipelined read
module ram_core #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a_raw, dout_b_raw
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [ADDR_WIDTH-1:0] addr_a_reg, addr_b_reg;

    // Write operations
    always @(posedge clk) begin
        if (we_a) ram[addr_a] <= din_a;
        if (we_b) ram[addr_b] <= din_b;
    end

    // Pipelined read operations
    always @(posedge clk) begin
        addr_a_reg <= addr_a;
        addr_b_reg <= addr_b;
        dout_a_raw <= ram[addr_a_reg];
        dout_b_raw <= ram[addr_b_reg];
    end
endmodule

// Pipelined output control module for port A
module output_control_a #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire oe_a,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg valid_out
);

    reg oe_a_reg;
    reg [DATA_WIDTH-1:0] data_in_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= 0;
            valid_out <= 0;
            oe_a_reg <= 0;
            data_in_reg <= 0;
        end else begin
            oe_a_reg <= oe_a;
            data_in_reg <= data_in;
            if (oe_a_reg)
                data_out <= data_in_reg;
            valid_out <= oe_a_reg;
        end
    end
endmodule

// Pipelined output control module for port B
module output_control_b #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire oe_b,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg valid_out
);

    reg oe_b_reg;
    reg [DATA_WIDTH-1:0] data_in_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= 0;
            valid_out <= 0;
            oe_b_reg <= 0;
            data_in_reg <= 0;
        end else begin
            oe_b_reg <= oe_b;
            data_in_reg <= data_in;
            if (oe_b_reg)
                data_out <= data_in_reg;
            valid_out <= oe_b_reg;
        end
    end
endmodule

// Pipelined two's complement subtractor module
module twos_complement_subtractor #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire sub_en,
    input wire [DATA_WIDTH-1:0] operand_a,
    input wire [DATA_WIDTH-1:0] operand_b,
    output reg [DATA_WIDTH-1:0] result,
    output reg overflow,
    output reg valid_out
);

    reg [DATA_WIDTH-1:0] operand_a_reg, operand_b_reg;
    reg [DATA_WIDTH-1:0] neg_operand_b;
    reg [DATA_WIDTH:0] sum;
    reg sub_en_reg;

    // Stage 1: Register inputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            operand_a_reg <= 0;
            operand_b_reg <= 0;
            sub_en_reg <= 0;
        end else begin
            operand_a_reg <= operand_a;
            operand_b_reg <= operand_b;
            sub_en_reg <= sub_en;
        end
    end

    // Stage 2: Calculate two's complement and perform addition
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            result <= 0;
            overflow <= 0;
            valid_out <= 0;
        end else if (sub_en_reg) begin
            neg_operand_b = ~operand_b_reg + 1'b1;
            sum = {1'b0, operand_a_reg} + {1'b0, neg_operand_b};
            result <= sum[DATA_WIDTH-1:0];
            overflow <= (operand_a_reg[DATA_WIDTH-1] == operand_b_reg[DATA_WIDTH-1]) && 
                       (sum[DATA_WIDTH-1] != operand_a_reg[DATA_WIDTH-1]);
            valid_out <= 1;
        end else begin
            valid_out <= 0;
        end
    end
endmodule

// Top-level module with pipelined architecture
module sync_dual_port_ram_with_subtraction #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire oe_a, oe_b,
    input wire sub_en,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output wire [DATA_WIDTH-1:0] dout_a, dout_b,
    output wire [DATA_WIDTH-1:0] sub_result,
    output wire sub_overflow,
    output wire dout_a_valid,
    output wire dout_b_valid,
    output wire sub_valid
);

    wire [DATA_WIDTH-1:0] dout_a_raw, dout_b_raw;

    ram_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) ram_core_inst (
        .clk(clk),
        .rst(rst),
        .we_a(we_a),
        .we_b(we_b),
        .addr_a(addr_a),
        .addr_b(addr_b),
        .din_a(din_a),
        .din_b(din_b),
        .dout_a_raw(dout_a_raw),
        .dout_b_raw(dout_b_raw)
    );

    output_control_a #(
        .DATA_WIDTH(DATA_WIDTH)
    ) output_control_a_inst (
        .clk(clk),
        .rst(rst),
        .oe_a(oe_a),
        .data_in(dout_a_raw),
        .data_out(dout_a),
        .valid_out(dout_a_valid)
    );

    output_control_b #(
        .DATA_WIDTH(DATA_WIDTH)
    ) output_control_b_inst (
        .clk(clk),
        .rst(rst),
        .oe_b(oe_b),
        .data_in(dout_b_raw),
        .data_out(dout_b),
        .valid_out(dout_b_valid)
    );
    
    twos_complement_subtractor #(
        .DATA_WIDTH(DATA_WIDTH)
    ) subtractor_inst (
        .clk(clk),
        .rst(rst),
        .sub_en(sub_en),
        .operand_a(dout_a_raw),
        .operand_b(dout_b_raw),
        .result(sub_result),
        .overflow(sub_overflow),
        .valid_out(sub_valid)
    );
endmodule