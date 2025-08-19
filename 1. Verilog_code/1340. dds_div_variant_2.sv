//SystemVerilog
// Top-level module
module dds_div #(
    parameter FTW = 32'h1999_9999
) (
    input wire clk,
    input wire rst,
    output wire clk_out
);

    // Internal signals for module connections
    wire [31:0] phase_acc;
    
    // Instantiate phase accumulator module
    phase_accumulator #(
        .FTW(FTW)
    ) phase_acc_inst (
        .clk(clk),
        .rst(rst),
        .phase_acc(phase_acc)
    );
    
    // Instantiate output generator module
    output_generator output_gen_inst (
        .clk(clk),
        .rst(rst),
        .phase_acc(phase_acc),
        .clk_out(clk_out)
    );

endmodule

// Phase accumulator module with carry-lookahead adder implementation
module phase_accumulator #(
    parameter FTW = 32'h1999_9999
) (
    input wire clk,
    input wire rst,
    output reg [31:0] phase_acc
);

    wire [31:0] next_phase_acc;
    
    // Instantiate carry-lookahead adder
    cla_32bit cla_adder (
        .a(phase_acc),
        .b(FTW),
        .sum(next_phase_acc)
    );

    always @(posedge clk) begin
        if (rst) begin
            phase_acc <= 32'b0;
        end else begin
            phase_acc <= next_phase_acc;
        end
    end

endmodule

// 32-bit Carry-Lookahead Adder
module cla_32bit (
    input wire [31:0] a,
    input wire [31:0] b,
    output wire [31:0] sum
);
    wire [7:0] group_carry;
    wire dummy_carry;

    // Divide into 8 blocks of 4-bit CLA
    cla_4bit cla0 (.a(a[3:0]), .b(b[3:0]), .cin(1'b0), .sum(sum[3:0]), .cout(group_carry[0]));
    cla_4bit cla1 (.a(a[7:4]), .b(b[7:4]), .cin(group_carry[0]), .sum(sum[7:4]), .cout(group_carry[1]));
    cla_4bit cla2 (.a(a[11:8]), .b(b[11:8]), .cin(group_carry[1]), .sum(sum[11:8]), .cout(group_carry[2]));
    cla_4bit cla3 (.a(a[15:12]), .b(b[15:12]), .cin(group_carry[2]), .sum(sum[15:12]), .cout(group_carry[3]));
    cla_4bit cla4 (.a(a[19:16]), .b(b[19:16]), .cin(group_carry[3]), .sum(sum[19:16]), .cout(group_carry[4]));
    cla_4bit cla5 (.a(a[23:20]), .b(b[23:20]), .cin(group_carry[4]), .sum(sum[23:20]), .cout(group_carry[5]));
    cla_4bit cla6 (.a(a[27:24]), .b(b[27:24]), .cin(group_carry[5]), .sum(sum[27:24]), .cout(group_carry[6]));
    cla_4bit cla7 (.a(a[31:28]), .b(b[31:28]), .cin(group_carry[6]), .sum(sum[31:28]), .cout(dummy_carry));

endmodule

// 4-bit Carry-Lookahead Adder
module cla_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    input wire cin,
    output wire [3:0] sum,
    output wire cout
);
    wire [3:0] p; // Propagate
    wire [3:0] g; // Generate
    wire [4:0] c; // Carry

    // Generate propagate and generate signals
    assign p = a ^ b;
    assign g = a & b;

    // Carry calculation
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);

    // Sum calculation
    assign sum = p ^ {c[3:0]};
    
    // Carry out
    assign cout = c[4];
endmodule

// Output generator module - generates clock output from phase accumulator MSB
module output_generator (
    input wire clk,
    input wire rst,
    input wire [31:0] phase_acc,
    output reg clk_out
);

    always @(posedge clk) begin
        if (rst) begin
            clk_out <= 1'b0;
        end else begin
            clk_out <= phase_acc[31];
        end
    end

endmodule