module recursive_shifter #(parameter N=16) (
    input [N-1:0] data,
    input [$clog2(N)-1:0] shift,
    output [N-1:0] result
);
localparam LOG2_N = $clog2(N);

// 定义所有阶段的线
wire [N-1:0] stage0, stage1, stage2, stage3, stage4;

// 第一阶段
assign stage0 = data;

// 中间阶段
generate
    if(LOG2_N > 0) begin: stage0_gen
        assign stage1 = shift[0] ? {stage0[N-2:0], stage0[N-1]} : stage0;
    end else begin: stage0_bypass
        assign stage1 = stage0;
    end
    
    if(LOG2_N > 1) begin: stage1_gen
        assign stage2 = shift[1] ? {stage1[N-3:0], stage1[N-1:N-2]} : stage1;
    end else begin: stage1_bypass
        assign stage2 = stage1;
    end
    
    if(LOG2_N > 2) begin: stage2_gen
        assign stage3 = shift[2] ? {stage2[N-5:0], stage2[N-1:N-4]} : stage2;
    end else begin: stage2_bypass
        assign stage3 = stage2;
    end
    
    if(LOG2_N > 3) begin: stage3_gen
        assign stage4 = shift[3] ? {stage3[N-9:0], stage3[N-1:N-8]} : stage3;
    end else begin: stage3_bypass
        assign stage4 = stage3;
    end
endgenerate

// 最终输出
assign result = (LOG2_N <= 1) ? stage1 :
               (LOG2_N <= 2) ? stage2 :
               (LOG2_N <= 3) ? stage3 : stage4;
endmodule