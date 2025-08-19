//SystemVerilog
module usb_bulk_endpoint_ctrl #(
    parameter MAX_PACKET_SIZE = 64,
    parameter BUFFER_DEPTH = 8
)(
    input wire clk_i, rst_n_i,
    input wire [7:0] data_i,
    input wire data_valid_i,
    input wire token_received_i,
    input wire [3:0] endpoint_i,
    output wire [7:0] data_o,
    output wire data_valid_o,
    output wire buffer_full_o,
    output wire buffer_empty_o,
    output wire [1:0] response_o
);
    // 内部信号定义
    wire [1:0] state;
    wire [$clog2(BUFFER_DEPTH)-1:0] write_ptr, read_ptr;
    wire [$clog2(BUFFER_DEPTH):0] count;
    wire [7:0] data_i_reg;
    wire data_valid_i_reg;
    wire [7:0] buffer_data_out;
    
    // 输入重定时模块实例化
    input_synchronizer input_sync_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .data_i(data_i),
        .data_valid_i(data_valid_i),
        .data_i_reg(data_i_reg),
        .data_valid_i_reg(data_valid_i_reg)
    );
    
    // 状态控制器模块实例化
    state_controller state_ctrl_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .token_received_i(token_received_i),
        .endpoint_i(endpoint_i),
        .buffer_full_i(buffer_full_o),
        .buffer_empty_i(buffer_empty_o),
        .state_o(state),
        .response_o(response_o)
    );
    
    // 缓冲区管理模块实例化
    buffer_manager #(
        .BUFFER_DEPTH(BUFFER_DEPTH)
    ) buffer_mgr_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .state_i(state),
        .data_i(data_i_reg),
        .data_valid_i(data_valid_i_reg),
        .write_ptr_o(write_ptr),
        .read_ptr_o(read_ptr),
        .count_o(count),
        .buffer_data_o(buffer_data_out),
        .buffer_full_o(buffer_full_o),
        .buffer_empty_o(buffer_empty_o)
    );
    
    // 输出控制模块实例化
    output_controller output_ctrl_inst (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .state_i(state),
        .buffer_data_i(buffer_data_out),
        .buffer_empty_i(buffer_empty_o),
        .data_o(data_o),
        .data_valid_o(data_valid_o)
    );
    
endmodule

// 输入重定时模块
module input_synchronizer (
    input wire clk_i,
    input wire rst_n_i,
    input wire [7:0] data_i,
    input wire data_valid_i,
    output reg [7:0] data_i_reg,
    output reg data_valid_i_reg
);
    // 输入信号寄存器化
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            data_i_reg <= 8'h0;
            data_valid_i_reg <= 1'b0;
        end else begin
            data_i_reg <= data_i;
            data_valid_i_reg <= data_valid_i;
        end
    end
endmodule

// 状态控制器模块
module state_controller (
    input wire clk_i,
    input wire rst_n_i,
    input wire token_received_i,
    input wire [3:0] endpoint_i,
    input wire buffer_full_i,
    input wire buffer_empty_i,
    output reg [1:0] state_o,
    output reg [1:0] response_o
);
    // 状态编码定义
    localparam IDLE = 2'b00, RX = 2'b01, TX = 2'b10, STALL = 2'b11;
    
    // 状态寄存器和下一状态
    reg [1:0] next_state;
    
    // 状态转换逻辑
    always @(*) begin
        next_state = state_o; // 默认保持当前状态
        
        case(state_o)
            IDLE: begin
                if (token_received_i && endpoint_i[3:0] != 4'h0)
                    next_state = RX;
            end
            RX: begin
                if (buffer_full_i)
                    next_state = IDLE;
            end
            TX: begin
                if (buffer_empty_i)
                    next_state = IDLE;
            end
            default: next_state = state_o;
        endcase
    end
    
    // 状态寄存器更新
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            state_o <= IDLE;
            response_o <= 2'b00;
        end else begin
            state_o <= next_state;
            response_o <= next_state; // 使用状态作为响应
        end
    end
endmodule

// 缓冲区管理模块
module buffer_manager #(
    parameter BUFFER_DEPTH = 8
)(
    input wire clk_i,
    input wire rst_n_i,
    input wire [1:0] state_i,
    input wire [7:0] data_i,
    input wire data_valid_i,
    output reg [$clog2(BUFFER_DEPTH)-1:0] write_ptr_o,
    output reg [$clog2(BUFFER_DEPTH)-1:0] read_ptr_o,
    output reg [$clog2(BUFFER_DEPTH):0] count_o,
    output wire [7:0] buffer_data_o,
    output wire buffer_full_o,
    output wire buffer_empty_o
);
    // 状态编码定义
    localparam IDLE = 2'b00, RX = 2'b01, TX = 2'b10, STALL = 2'b11;
    
    // 缓冲区声明
    reg [7:0] buffer [0:BUFFER_DEPTH-1];
    
    // 计算下一个写指针位置
    wire [$clog2(BUFFER_DEPTH)-1:0] write_ptr_next = (write_ptr_o == BUFFER_DEPTH-1) ? 0 : write_ptr_o + 1;
    wire [$clog2(BUFFER_DEPTH)-1:0] read_ptr_next = (read_ptr_o == BUFFER_DEPTH-1) ? 0 : read_ptr_o + 1;
    
    // 缓冲区状态信号
    assign buffer_full_o = (count_o == BUFFER_DEPTH-1) && data_valid_i && (state_i == RX);
    assign buffer_empty_o = (count_o == 0);
    
    // 输出当前读指针位置的数据
    assign buffer_data_o = buffer[read_ptr_o];
    
    // 缓冲区管理逻辑
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            write_ptr_o <= 0;
            read_ptr_o <= 0;
            count_o <= 0;
        end else begin
            // 写入逻辑
            if (data_valid_i && !buffer_full_o && state_i == RX) begin
                buffer[write_ptr_o] <= data_i;
                write_ptr_o <= write_ptr_next;
                count_o <= count_o + 1;
            end
            
            // 读取逻辑
            if (state_i == TX && !buffer_empty_o) begin
                read_ptr_o <= read_ptr_next;
                count_o <= count_o - 1;
            end
        end
    end
endmodule

// 输出控制模块
module output_controller (
    input wire clk_i,
    input wire rst_n_i,
    input wire [1:0] state_i,
    input wire [7:0] buffer_data_i,
    input wire buffer_empty_i,
    output reg [7:0] data_o,
    output reg data_valid_o
);
    // 状态编码定义
    localparam IDLE = 2'b00, RX = 2'b01, TX = 2'b10, STALL = 2'b11;
    
    // 输出控制逻辑
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            data_o <= 8'h0;
            data_valid_o <= 1'b0;
        end else begin
            data_valid_o <= (state_i == TX) && !buffer_empty_i;
            
            if (state_i == TX && !buffer_empty_i) begin
                data_o <= buffer_data_i;
            end
        end
    end
endmodule