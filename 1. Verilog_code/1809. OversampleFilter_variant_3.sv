//SystemVerilog
module OversampleFilter #(parameter OVERSAMPLE=3) (
    input clk, 
    input din,
    output reg dout
);
    reg [OVERSAMPLE-1:0] sample_buf;
    wire [3:0] count;
    
    // 桶形移位器实现
    always @(posedge clk) begin
        sample_buf <= {sample_buf[OVERSAMPLE-2:0], din};
        dout <= (count > (OVERSAMPLE/2));
    end
    
    // 优化后的计数器实现
    BarrelShifterCounter #(.WIDTH(OVERSAMPLE)) counter (
        .bits(sample_buf),
        .count(count)
    );
endmodule

module BarrelShifterCounter #(parameter WIDTH=3) (
    input [WIDTH-1:0] bits,
    output [3:0] count
);
    wire [WIDTH-1:0] G, P;
    genvar i;
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_gp
            assign G[i] = bits[i];
            assign P[i] = 0;
        end
    endgenerate
    
    // 桶形移位器结构实现前缀计算
    wire [WIDTH-1:0] G_final;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: barrel_stage
            if (i == 0) begin
                assign G_final[i] = G[i];
            end else begin
                assign G_final[i] = G[i] | (P[i] & G_final[i-1]);
            end
        end
    endgenerate
    
    // 并行加法器实现最终计数
    wire [1:0] sum_low = G_final[0] + G_final[1];
    wire [1:0] sum_high = (WIDTH > 2) ? (G_final[2] + (WIDTH > 3 ? G_final[3] : 0)) : 0;
    assign count = sum_low + sum_high;
endmodule