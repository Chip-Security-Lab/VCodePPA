//SystemVerilog
module MuxLatch #(parameter DW=4, SEL=2) (
    input clk, 
    input [2**SEL-1:0][DW-1:0] din,
    input [SEL-1:0] sel,
    output reg [DW-1:0] dout
);
    always @(posedge clk) 
        dout <= din[sel];
endmodule

module ParallelPrefixSubtractor #(parameter WIDTH=8) (
    input clk,
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output reg [WIDTH-1:0] diff,
    output reg borrow
);
    // Generate and propagate signals
    wire [WIDTH-1:0] g, p;
    reg [WIDTH-1:0] g_reg, p_reg;
    
    // Parallel prefix computation signals
    reg [WIDTH-1:0] g_stage1, p_stage1;
    reg [WIDTH-1:0] g_stage2, p_stage2;
    reg [WIDTH-1:0] g_stage3, p_stage3;
    
    // Generate and propagate computation
    genvar i;
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin : gen_prop
            assign g[i] = ~a[i] & b[i];
            assign p[i] = a[i] ^ b[i];
        end
    endgenerate
    
    // Pipeline registers
    always @(posedge clk) begin
        g_reg <= g;
        p_reg <= p;
    end
    
    // Parallel prefix computation
    always @(posedge clk) begin
        // Stage 1
        g_stage1[0] <= g_reg[0];
        p_stage1[0] <= p_reg[0];
        for(integer i = 1; i < WIDTH; i = i + 1) begin
            g_stage1[i] <= g_reg[i] | (p_reg[i] & g_reg[i-1]);
            p_stage1[i] <= p_reg[i] & p_reg[i-1];
        end
        
        // Stage 2
        g_stage2[0] <= g_stage1[0];
        p_stage2[0] <= p_stage1[0];
        g_stage2[1] <= g_stage1[1];
        p_stage2[1] <= p_stage1[1];
        for(integer i = 2; i < WIDTH; i = i + 1) begin
            g_stage2[i] <= g_stage1[i] | (p_stage1[i] & g_stage1[i-2]);
            p_stage2[i] <= p_stage1[i] & p_stage1[i-2];
        end
        
        // Stage 3
        g_stage3[0] <= g_stage2[0];
        p_stage3[0] <= p_stage2[0];
        g_stage3[1] <= g_stage2[1];
        p_stage3[1] <= p_stage2[1];
        g_stage3[2] <= g_stage2[2];
        p_stage3[2] <= p_stage2[2];
        g_stage3[3] <= g_stage2[3];
        p_stage3[3] <= p_stage2[3];
        for(integer i = 4; i < WIDTH; i = i + 1) begin
            g_stage3[i] <= g_stage2[i] | (p_stage2[i] & g_stage2[i-4]);
            p_stage3[i] <= p_stage2[i] & p_stage2[i-4];
        end
        
        // Final difference computation
        diff[0] <= p_reg[0];
        for(integer i = 1; i < WIDTH; i = i + 1) begin
            diff[i] <= p_reg[i] ^ g_stage3[i-1];
        end
        
        borrow <= g_stage3[WIDTH-1];
    end
endmodule

module TopModule (
    input clk,
    input [7:0] a,
    input [7:0] b,
    input [1:0] sel,
    input [3:0][3:0] mux_data,
    output [7:0] diff_out,
    output borrow_out,
    output [3:0] mux_out
);
    wire [3:0] mux_result;
    
    MuxLatch #(.DW(4), .SEL(2)) mux_inst (
        .clk(clk),
        .din(mux_data),
        .sel(sel),
        .dout(mux_result)
    );
    
    ParallelPrefixSubtractor #(.WIDTH(8)) sub_inst (
        .clk(clk),
        .a(a),
        .b(b),
        .diff(diff_out),
        .borrow(borrow_out)
    );
    
    assign mux_out = mux_result;
endmodule