//SystemVerilog
module vector_ismu #(
    parameter VECTOR_WIDTH = 8
)(
    input  wire                    clk_i,
    input  wire                    rst_n_i,
    input  wire [VECTOR_WIDTH-1:0] src_i,
    input  wire [VECTOR_WIDTH-1:0] mask_i,
    input  wire                    ack_i,
    output wire [VECTOR_WIDTH-1:0] vector_o,
    output wire                    valid_o
);
    // 内部连线
    wire [VECTOR_WIDTH-1:0] src_r;
    wire [VECTOR_WIDTH-1:0] mask_r;
    wire                    ack_r;
    wire [VECTOR_WIDTH-1:0] masked_src_r;

    // 输入寄存器化模块实例
    input_register #(
        .VECTOR_WIDTH(VECTOR_WIDTH)
    ) u_input_register (
        .clk_i     (clk_i),
        .rst_n_i   (rst_n_i),
        .src_i     (src_i),
        .mask_i    (mask_i),
        .ack_i     (ack_i),
        .src_o     (src_r),
        .mask_o    (mask_r),
        .ack_o     (ack_r)
    );

    // 掩码逻辑处理模块实例
    mask_processor #(
        .VECTOR_WIDTH(VECTOR_WIDTH)
    ) u_mask_processor (
        .clk_i        (clk_i),
        .rst_n_i      (rst_n_i),
        .src_i        (src_r),
        .mask_i       (mask_r),
        .masked_src_o (masked_src_r)
    );

    // 输出控制模块实例
    output_controller #(
        .VECTOR_WIDTH(VECTOR_WIDTH)
    ) u_output_controller (
        .clk_i        (clk_i),
        .rst_n_i      (rst_n_i),
        .masked_src_i (masked_src_r),
        .ack_i        (ack_r),
        .vector_o     (vector_o),
        .valid_o      (valid_o)
    );
endmodule

// 输入寄存器化模块
module input_register #(
    parameter VECTOR_WIDTH = 8
)(
    input  wire                    clk_i,
    input  wire                    rst_n_i,
    input  wire [VECTOR_WIDTH-1:0] src_i,
    input  wire [VECTOR_WIDTH-1:0] mask_i,
    input  wire                    ack_i,
    output reg  [VECTOR_WIDTH-1:0] src_o,
    output reg  [VECTOR_WIDTH-1:0] mask_o,
    output reg                     ack_o
);
    // 输入寄存器化，减少输入到第一级寄存器的延迟
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            src_o  <= {VECTOR_WIDTH{1'b0}};
            mask_o <= {VECTOR_WIDTH{1'b0}};
            ack_o  <= 1'b0;
        end else begin
            src_o  <= src_i;
            mask_o <= mask_i;
            ack_o  <= ack_i;
        end
    end
endmodule

// 掩码处理模块
module mask_processor #(
    parameter VECTOR_WIDTH = 8
)(
    input  wire                    clk_i,
    input  wire                    rst_n_i,
    input  wire [VECTOR_WIDTH-1:0] src_i,
    input  wire [VECTOR_WIDTH-1:0] mask_i,
    output reg  [VECTOR_WIDTH-1:0] masked_src_o
);
    // 预计算masked_src并寄存
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            masked_src_o <= {VECTOR_WIDTH{1'b0}};
        end else begin
            masked_src_o <= src_i & ~mask_i;
        end
    end
endmodule

// 输出控制模块
module output_controller #(
    parameter VECTOR_WIDTH = 8
)(
    input  wire                    clk_i,
    input  wire                    rst_n_i,
    input  wire [VECTOR_WIDTH-1:0] masked_src_i,
    input  wire                    ack_i,
    output reg  [VECTOR_WIDTH-1:0] vector_o,
    output reg                     valid_o
);
    // 待处理数据寄存器
    reg [VECTOR_WIDTH-1:0] pending_r;

    // 主逻辑
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            pending_r <= {VECTOR_WIDTH{1'b0}};
            vector_o  <= {VECTOR_WIDTH{1'b0}};
            valid_o   <= 1'b0;
        end else begin
            pending_r <= pending_r | masked_src_i;
            
            if (ack_i) begin
                pending_r <= {VECTOR_WIDTH{1'b0}};
                valid_o   <= 1'b0;
            end else if (|pending_r) begin
                valid_o   <= 1'b1;
                vector_o  <= pending_r;
            end
        end
    end
endmodule