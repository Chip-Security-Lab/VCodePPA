//SystemVerilog
module circular_buffer (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire write_en,
    input wire read_en,
    output reg [7:0] data_out,
    output reg empty,
    output reg full
);
    reg [7:0] mem [0:3];
    reg [1:0] wr_ptr, rd_ptr;
    reg [2:0] count;
    
    // 寄存输入信号，将寄存器前移到组合逻辑之后
    reg [7:0] data_in_reg;
    reg write_en_reg, read_en_reg;
    
    // 将组合逻辑结果直接连接到寄存器
    wire [2:0] count_after_write;
    wire [2:0] count_after_read;
    
    // 预先计算下一个状态值
    wire [1:0] next_wr_ptr = wr_ptr + (write_en_reg && !full);
    wire [1:0] next_rd_ptr = rd_ptr + (read_en_reg && !empty);
    wire next_empty = (write_en_reg && !full) ? 1'b0 : ((read_en_reg && (count == 3'b001)) ? 1'b1 : (count == 0));
    wire next_full = (read_en_reg && !empty) ? 1'b0 : ((write_en_reg && (count == 3'b011)) ? 1'b1 : (count == 4));
    
    han_carlson_adder #(.WIDTH(3)) add_for_write (
        .a(count),
        .b(3'b001),
        .cin(1'b0),
        .sum(count_after_write),
        .cout()
    );
    
    han_carlson_adder #(.WIDTH(3)) sub_for_read (
        .a(count),
        .b(3'b111), // -1 in 2's complement
        .cin(1'b1), // To complete 2's complement subtraction
        .sum(count_after_read),
        .cout()
    );
    
    // 输入寄存器 - 将寄存器前移到组合逻辑之前
    always @(posedge clk) begin
        if (rst) begin
            data_in_reg <= 0;
            write_en_reg <= 0;
            read_en_reg <= 0;
        end else begin
            data_in_reg <= data_in;
            write_en_reg <= write_en;
            read_en_reg <= read_en;
        end
    end
    
    // 主逻辑 - 使用已寄存的输入信号
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
            empty <= 1;
            full <= 0;
            data_out <= 0;
        end else begin
            if (write_en_reg && !full) begin
                mem[wr_ptr] <= data_in_reg;
                wr_ptr <= next_wr_ptr;
                count <= (read_en_reg && !empty) ? count : count_after_write;
            end
            else if (read_en_reg && !empty) begin
                data_out <= mem[rd_ptr];
                rd_ptr <= next_rd_ptr;
                count <= count_after_read;
            end
            empty <= next_empty;
            full <= next_full;
        end
    end
endmodule

module han_carlson_adder #(
    parameter WIDTH = 8
) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    input wire cin,
    output wire [WIDTH-1:0] sum,
    output wire cout
);
    // Pre-computation
    wire [WIDTH-1:0] p, g;
    wire [WIDTH:0] c;
    
    // 寄存输入信号
    reg [WIDTH-1:0] a_reg, b_reg;
    reg cin_reg;
    
    // Generate p (propagate) and g (generate) signals
    assign p = a ^ b;
    assign g = a & b;
    
    // First stage - Computing initial carries
    wire [WIDTH-1:0] pp, gg;
    assign pp[0] = p[0];
    assign gg[0] = g[0];
    
    // Han-Carlson even-indexed prefix computation
    wire [WIDTH-1:0] g_even, p_even;
    
    // Initialize carry-in
    assign c[0] = cin;
    
    // First level of prefix computation for even bits
    genvar i;
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin : gen_even_prefix_level1
            // For even indices (0, 2, 4...)
            assign g_even[2*i] = g[2*i] | (p[2*i] & (i == 0 ? cin : g[2*i-1]));
            assign p_even[2*i] = p[2*i] & (i == 0 ? 1'b1 : p[2*i-1]);
        end
    endgenerate
    
    // Second level of prefix computation for even bits (prefix tree)
    wire [WIDTH-1:0] g_even_l2, p_even_l2;
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin : gen_even_prefix_level2
            if (i == 0) begin
                assign g_even_l2[2*i] = g_even[2*i];
                assign p_even_l2[2*i] = p_even[2*i];
            end else begin
                assign g_even_l2[2*i] = g_even[2*i] | (p_even[2*i] & g_even_l2[2*(i-1)]);
                assign p_even_l2[2*i] = p_even[2*i] & p_even_l2[2*(i-1)];
            end
        end
    endgenerate
    
    // Assign carry bits for even indices
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin : gen_even_carry
            assign c[2*i+1] = g_even_l2[2*i] | (p_even_l2[2*i] & c[0]);
        end
    endgenerate
    
    // Compute carries for odd indices based on even carries
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin : gen_odd_carry
            if (2*i+2 < WIDTH+1)
                assign c[2*i+2] = g[2*i+1] | (p[2*i+1] & c[2*i+1]);
        end
    endgenerate
    
    // Final sum computation
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_sum
            assign sum[i] = p[i] ^ c[i];
        end
    endgenerate
    
    // Carry output
    assign cout = c[WIDTH];
endmodule