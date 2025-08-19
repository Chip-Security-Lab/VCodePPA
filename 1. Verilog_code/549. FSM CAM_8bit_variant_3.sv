//SystemVerilog
module cam_9 (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    output reg match_flag,
    output reg [7:0] stored_data
);

    // 状态控制模块
    state_controller state_ctrl (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .stored_data(stored_data),
        .match_flag(match_flag)
    );

endmodule

module state_controller (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    output reg [7:0] stored_data,
    output reg match_flag
);

    // 状态定义
    localparam IDLE = 3'b000,
              STORE = 3'b001,
              COMPARE = 3'b010,
              UPDATE = 3'b011;
    
    reg [2:0] state;
    reg [7:0] data_stage1;
    reg [7:0] data_stage2;
    reg compare_result;
    
    // 状态机逻辑
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            stored_data <= 8'b0;
            match_flag <= 1'b0;
            data_stage1 <= 8'b0;
            data_stage2 <= 8'b0;
            compare_result <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    data_stage1 <= data_in;
                    state <= STORE;
                end
                STORE: begin
                    data_stage2 <= data_stage1;
                    state <= COMPARE;
                end
                COMPARE: begin
                    compare_result <= (data_stage2 == data_in);
                    state <= UPDATE;
                end
                UPDATE: begin
                    stored_data <= data_stage2;
                    match_flag <= compare_result;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end

endmodule