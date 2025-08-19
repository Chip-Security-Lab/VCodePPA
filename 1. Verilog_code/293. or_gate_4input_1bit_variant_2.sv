//SystemVerilog
// 顶层模块
module subtractor_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire [3:0] difference,
    output wire borrow_out
);
    // 内部连接信号
    wire [3:0] internal_borrows;
    
    // 实例化借位减法器结构
    borrow_subtractor_module borrow_subtractor_inst (
        .minuend(a),
        .subtrahend(b),
        .internal_borrows(internal_borrows),
        .difference(difference),
        .borrow_out(borrow_out)
    );
endmodule

// 借位减法器模块
module borrow_subtractor_module (
    input wire [3:0] minuend,
    input wire [3:0] subtrahend,
    output wire [3:0] internal_borrows,
    output wire [3:0] difference,
    output wire borrow_out
);
    // 生成各位的借位和差值
    full_subtractor_bit #(.PIPELINE_STAGES(1)) sub_bit0 (
        .a(minuend[0]),
        .b(subtrahend[0]),
        .bin(1'b0),
        .diff(difference[0]),
        .bout(internal_borrows[0])
    );
    
    full_subtractor_bit #(.PIPELINE_STAGES(1)) sub_bit1 (
        .a(minuend[1]),
        .b(subtrahend[1]),
        .bin(internal_borrows[0]),
        .diff(difference[1]),
        .bout(internal_borrows[1])
    );
    
    full_subtractor_bit #(.PIPELINE_STAGES(1)) sub_bit2 (
        .a(minuend[2]),
        .b(subtrahend[2]),
        .bin(internal_borrows[1]),
        .diff(difference[2]),
        .bout(internal_borrows[2])
    );
    
    full_subtractor_bit #(.PIPELINE_STAGES(1)) sub_bit3 (
        .a(minuend[3]),
        .b(subtrahend[3]),
        .bin(internal_borrows[2]),
        .diff(difference[3]),
        .bout(internal_borrows[3])
    );
    
    assign borrow_out = internal_borrows[3];
endmodule

// 参数化全减器模块
module full_subtractor_bit #(
    parameter PIPELINE_STAGES = 1
)(
    input wire a,
    input wire b,
    input wire bin,
    output wire diff,
    output wire bout
);
    generate
        if (PIPELINE_STAGES > 0) begin : pipelined
            reg [PIPELINE_STAGES-1:0] diff_pipe;
            reg [PIPELINE_STAGES-1:0] bout_pipe;
            
            always @(a or b or bin) begin
                // 计算差值：a ^ b ^ bin
                diff_pipe[0] <= a ^ b ^ bin;
                // 计算借位：(~a & b) | (bin & (~a | b))
                bout_pipe[0] <= (~a & b) | (bin & (~a | b));
            end
            
            genvar i;
            for (i = 1; i < PIPELINE_STAGES; i = i + 1) begin : pipe_stages
                always @(diff_pipe[i-1] or bout_pipe[i-1]) begin
                    diff_pipe[i] <= diff_pipe[i-1];
                    bout_pipe[i] <= bout_pipe[i-1];
                end
            end
            
            assign diff = diff_pipe[PIPELINE_STAGES-1];
            assign bout = bout_pipe[PIPELINE_STAGES-1];
        end else begin : combinational
            assign diff = a ^ b ^ bin;
            assign bout = (~a & b) | (bin & (~a | b));
        end
    endgenerate
endmodule