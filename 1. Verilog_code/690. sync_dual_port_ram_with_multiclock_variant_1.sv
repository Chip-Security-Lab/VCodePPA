//SystemVerilog
module sync_dual_port_ram_with_multiclock #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk_a, clk_b,
    input wire rst_a, rst_b,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] ram_a_reg, ram_b_reg;

    // Port A
    always @(posedge clk_a) begin
        if (rst_a) begin
            dout_a <= {DATA_WIDTH{1'b0}};
            ram_a_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            ram_a_reg <= ram[addr_a];
            if (we_a) begin
                ram[addr_a] <= din_a;
            end
            dout_a <= ram_a_reg;
        end
    end

    // Port B
    always @(posedge clk_b) begin
        if (rst_b) begin
            dout_b <= {DATA_WIDTH{1'b0}};
            ram_b_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            ram_b_reg <= ram[addr_b];
            if (we_b) begin
                ram[addr_b] <= din_b;
            end
            dout_b <= ram_b_reg;
        end
    end
endmodule

// Two's complement subtraction module
module twos_complement_subtractor #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire [DATA_WIDTH-1:0] a,
    input wire [DATA_WIDTH-1:0] b,
    output reg [DATA_WIDTH-1:0] result,
    output reg overflow
);

    // Two's complement of b
    wire [DATA_WIDTH-1:0] b_twos_complement;
    wire [DATA_WIDTH:0] sum;
    
    // Calculate two's complement of b (invert bits and add 1)
    assign b_twos_complement = ~b + 1'b1;
    
    // Add a and b's two's complement
    assign sum = {1'b0, a} + {1'b0, b_twos_complement};
    
    // Detect overflow: if signs of a and b are different and result sign is same as b
    wire overflow_detect = (a[DATA_WIDTH-1] != b[DATA_WIDTH-1]) && 
                          (sum[DATA_WIDTH-1] == b[DATA_WIDTH-1]);
    
    always @(posedge clk) begin
        if (rst) begin
            result <= {DATA_WIDTH{1'b0}};
            overflow <= 1'b0;
        end else begin
            result <= sum[DATA_WIDTH-1:0];
            overflow <= overflow_detect;
        end
    end
endmodule

// Top-level module that combines RAM and subtractor
module ram_with_subtractor #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk_a, clk_b,
    input wire rst_a, rst_b,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output wire [DATA_WIDTH-1:0] dout_a, dout_b,
    
    // Subtraction interface
    input wire [DATA_WIDTH-1:0] sub_a,
    input wire [DATA_WIDTH-1:0] sub_b,
    output wire [DATA_WIDTH-1:0] sub_result,
    output wire sub_overflow
);

    // RAM instance
    sync_dual_port_ram_with_multiclock #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) ram_inst (
        .clk_a(clk_a),
        .clk_b(clk_b),
        .rst_a(rst_a),
        .rst_b(rst_b),
        .we_a(we_a),
        .we_b(we_b),
        .addr_a(addr_a),
        .addr_b(addr_b),
        .din_a(din_a),
        .din_b(din_b),
        .dout_a(dout_a),
        .dout_b(dout_b)
    );
    
    // Subtractor instance
    twos_complement_subtractor #(
        .DATA_WIDTH(DATA_WIDTH)
    ) subtractor_inst (
        .clk(clk_a),
        .rst(rst_a),
        .a(sub_a),
        .b(sub_b),
        .result(sub_result),
        .overflow(sub_overflow)
    );
    
endmodule