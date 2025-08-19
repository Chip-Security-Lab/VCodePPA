//SystemVerilog
module AtomicOpBridge #(
    parameter DATA_W = 32
)(
    input clk, rst_n,
    input [1:0] op_type, // 0:ADD,1:AND,2:OR,3:XOR
    input [DATA_W-1:0] operand,
    output reg [DATA_W-1:0] reg_data
);
    reg [DATA_W-1:0] next_data;
    
    // Brent-Kung adder implementation
    wire [DATA_W-1:0] brent_kung_sum;
    wire brent_kung_cout;
    
    BrentKungAdder #(
        .WIDTH(DATA_W)
    ) brent_kung_adder_inst (
        .a(reg_data),
        .b(operand),
        .cin(1'b0),
        .sum(brent_kung_sum),
        .cout(brent_kung_cout)
    );
    
    // 组合逻辑部分 - 计算下一个状态
    always @(*) begin
        case(op_type)
            2'b00: next_data = brent_kung_sum;
            2'b01: next_data = reg_data & operand;
            2'b10: next_data = reg_data | operand;
            2'b11: next_data = reg_data ^ operand;
            default: next_data = reg_data;
        endcase
    end
    
    // 时序逻辑部分 - 更新寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            reg_data <= {DATA_W{1'b0}};
        else 
            reg_data <= next_data;
    end
endmodule

// Brent-Kung Adder Module
module BrentKungAdder #(
    parameter WIDTH = 32
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input cin,
    output [WIDTH-1:0] sum,
    output cout
);
    // Generate and propagate signals
    wire [WIDTH-1:0] g, p;
    wire [WIDTH:0] c;
    
    // First level - generate and propagate
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_prop
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] ^ b[i];
        end
    endgenerate
    
    // Set carry-in
    assign c[0] = cin;
    
    // Brent-Kung prefix tree
    wire [WIDTH-1:0] g_level1, p_level1;
    wire [WIDTH-1:0] g_level2, p_level2;
    wire [WIDTH-1:0] g_level3, p_level3;
    
    // Level 1 - 2-bit groups
    genvar j;
    generate
        for (j = 0; j < WIDTH/2; j = j + 1) begin : level1
            if (j == 0) begin
                assign g_level1[j] = g[1] | (p[1] & g[0]);
                assign p_level1[j] = p[1] & p[0];
            end else begin
                assign g_level1[j] = g[2*j+1] | (p[2*j+1] & g[2*j]);
                assign p_level1[j] = p[2*j+1] & p[2*j];
            end
        end
    endgenerate
    
    // Level 2 - 4-bit groups
    generate
        for (j = 0; j < WIDTH/4; j = j + 1) begin : level2
            if (j == 0) begin
                assign g_level2[j] = g_level1[1] | (p_level1[1] & g_level1[0]);
                assign p_level2[j] = p_level1[1] & p_level1[0];
            end else begin
                assign g_level2[j] = g_level1[2*j+1] | (p_level1[2*j+1] & g_level1[2*j]);
                assign p_level2[j] = p_level1[2*j+1] & p_level1[2*j];
            end
        end
    endgenerate
    
    // Level 3 - 8-bit groups
    generate
        for (j = 0; j < WIDTH/8; j = j + 1) begin : level3
            if (j == 0) begin
                assign g_level3[j] = g_level2[1] | (p_level2[1] & g_level2[0]);
                assign p_level3[j] = p_level2[1] & p_level2[0];
            end else begin
                assign g_level3[j] = g_level2[2*j+1] | (p_level2[2*j+1] & g_level2[2*j]);
                assign p_level3[j] = p_level2[2*j+1] & p_level2[2*j];
            end
        end
    endgenerate
    
    // Carry computation
    genvar k;
    generate
        for (k = 1; k < WIDTH; k = k + 1) begin : carry_compute
            if (k == 1) begin
                assign c[k] = g[k-1] | (p[k-1] & c[k-1]);
            end else if (k == 2) begin
                assign c[k] = g_level1[0] | (p_level1[0] & c[0]);
            end else if (k == 4) begin
                assign c[k] = g_level2[0] | (p_level2[0] & c[0]);
            end else if (k == 8) begin
                assign c[k] = g_level3[0] | (p_level3[0] & c[0]);
            end else begin
                // For other positions, use the appropriate level
                if (k < 4) begin
                    assign c[k] = g[k-1] | (p[k-1] & c[k-1]);
                end else if (k < 8) begin
                    assign c[k] = g_level1[k/2-1] | (p_level1[k/2-1] & c[k-2]);
                end else begin
                    assign c[k] = g_level2[k/4-1] | (p_level2[k/4-1] & c[k-4]);
                end
            end
        end
    endgenerate
    
    // Sum computation
    genvar m;
    generate
        for (m = 0; m < WIDTH; m = m + 1) begin : sum_compute
            assign sum[m] = p[m] ^ c[m];
        end
    endgenerate
    
    // Final carry out
    assign cout = c[WIDTH];
endmodule