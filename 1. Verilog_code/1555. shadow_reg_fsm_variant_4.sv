//SystemVerilog
module shadow_reg_fsm #(parameter DW=4) (
    input clk, rst, trigger,
    input [DW-1:0] data_in,
    output [DW-1:0] data_out
);
    // Internal signals
    wire next_state;
    wire shadow_wr_en;
    wire data_out_wr_en;
    wire [DW-1:0] shadow_data;
    wire state;

    // Buffer for high fanout signals
    wire clk_buf, rst_buf;

    // Buffering clk and rst signals
    assign clk_buf = clk; // Add a buffer here if needed
    assign rst_buf = rst; // Add a buffer here if needed

    // 状态控制子模块
    fsm_controller #(
        .DW(DW)
    ) u_fsm_controller (
        .clk(clk_buf),
        .rst(rst_buf),
        .trigger(trigger),
        .state(state),
        .next_state(next_state),
        .shadow_wr_en(shadow_wr_en),
        .data_out_wr_en(data_out_wr_en)
    );

    // 数据路径子模块
    data_path #(
        .DW(DW)
    ) u_data_path (
        .clk(clk_buf),
        .rst(rst_buf),
        .data_in(data_in),
        .shadow_wr_en(shadow_wr_en),
        .data_out_wr_en(data_out_wr_en),
        .shadow_data(shadow_data),
        .data_out(data_out)
    );

    // 状态寄存器子模块
    state_register u_state_register (
        .clk(clk_buf),
        .rst(rst_buf),
        .next_state(next_state),
        .state(state)
    );
endmodule

module fsm_controller #(parameter DW=4) (
    input clk, rst, trigger,
    input state,
    output reg next_state,
    output reg shadow_wr_en,
    output reg data_out_wr_en
);
    // 根据当前状态和输入产生控制信号
    always @(*) begin
        // 默认值
        next_state = state;
        shadow_wr_en = 1'b0;
        data_out_wr_en = 1'b0;
        
        case(state)
            1'b0: begin
                if(trigger) begin
                    shadow_wr_en = 1'b1;
                    next_state = 1'b1;
                end
            end
            1'b1: begin
                data_out_wr_en = 1'b1;
                next_state = 1'b0;
            end
        endcase
    end
endmodule

module data_path #(parameter DW=4) (
    input clk, rst,
    input [DW-1:0] data_in,
    input shadow_wr_en, data_out_wr_en,
    output reg [DW-1:0] shadow_data,
    output reg [DW-1:0] data_out
);
    // 数据路径逻辑：管理shadow寄存器和data_out寄存器
    
    // Shadow 寄存器
    always @(posedge clk) begin
        if(rst) begin
            shadow_data <= {DW{1'b0}};
        end else if(shadow_wr_en) begin
            shadow_data <= data_in;
        end
    end
    
    // Data out 寄存器
    always @(posedge clk) begin
        if(rst) begin
            data_out <= {DW{1'b0}};
        end else if(data_out_wr_en) begin
            data_out <= shadow_data;
        end
    end
endmodule

module state_register (
    input clk, rst,
    input next_state,
    output reg state
);
    // 状态寄存器
    always @(posedge clk) begin
        if(rst) begin
            state <= 1'b0;
        end else begin
            state <= next_state;
        end
    end
endmodule