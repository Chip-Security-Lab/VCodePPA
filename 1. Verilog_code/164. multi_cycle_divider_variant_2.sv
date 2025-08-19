//SystemVerilog
module multi_cycle_divider (
    input clk,
    input reset,
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);

    // Control signals
    wire [2:0] iter_count;
    wire iter_en;
    wire iter_rst;
    
    // Data signals
    wire [7:0] dividend;
    wire [7:0] divisor;
    wire [7:0] div_quotient;
    wire [7:0] div_remainder;
    
    // Control unit
    control_unit u_control (
        .clk(clk),
        .reset(reset),
        .iter_count(iter_count),
        .iter_en(iter_en),
        .iter_rst(iter_rst)
    );
    
    // Iteration counter
    counter u_counter (
        .clk(clk),
        .reset(reset),
        .iter_en(iter_en),
        .iter_rst(iter_rst),
        .iter_count(iter_count)
    );
    
    // Goldschmidt divider data path
    data_path u_data (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .iter_count(iter_count),
        .dividend(dividend),
        .divisor(divisor),
        .quotient(div_quotient),
        .remainder(div_remainder)
    );
    
    // Output registers
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient <= 0;
            remainder <= 0;
        end else if (iter_count == 3) begin
            quotient <= div_quotient;
            remainder <= div_remainder;
        end
    end
    
endmodule

module control_unit (
    input clk,
    input reset,
    input [2:0] iter_count,
    output reg iter_en,
    output reg iter_rst
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            iter_en <= 0;
            iter_rst <= 1;
        end else begin
            iter_rst <= 0;
            iter_en <= (iter_count < 4);
        end
    end
endmodule

module counter (
    input clk,
    input reset,
    input iter_en,
    input iter_rst,
    output reg [2:0] iter_count
);
    always @(posedge clk or posedge reset) begin
        if (reset || iter_rst) begin
            iter_count <= 0;
        end else if (iter_en) begin
            iter_count <= iter_count + 1;
        end
    end
endmodule

module data_path (
    input clk,
    input reset,
    input [7:0] a,
    input [7:0] b,
    input [2:0] iter_count,
    output reg [7:0] dividend,
    output reg [7:0] divisor,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);
    reg [7:0] x, y;
    reg [7:0] f;
    reg [7:0] x_next, y_next;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            x <= 0;
            y <= 0;
            f <= 0;
            dividend <= 0;
            divisor <= 0;
            quotient <= 0;
            remainder <= 0;
        end else if (iter_count == 0) begin
            x <= a;
            y <= b;
            f <= 8'h80 - b;
            dividend <= a;
            divisor <= b;
        end else if (iter_count < 4) begin
            x_next = x + (x * f >> 7);
            y_next = y + (y * f >> 7);
            f = 8'h100 - y_next;
            x = x_next;
            y = y_next;
            
            if (iter_count == 3) begin
                quotient <= x;
                remainder <= a - (x * b);
            end
        end
    end
endmodule