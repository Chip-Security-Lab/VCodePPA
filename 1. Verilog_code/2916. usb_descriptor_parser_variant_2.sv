//SystemVerilog
module usb_descriptor_parser(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire start_parse,
    output reg [15:0] vendor_id,
    output reg [15:0] product_id,
    output reg [7:0] device_class,
    output reg [7:0] max_packet_size,
    output reg [7:0] num_configurations,
    output reg parsing_complete,
    output reg [2:0] parse_state
);
    localparam IDLE = 3'd0;
    localparam LENGTH = 3'd1;
    localparam TYPE = 3'd2;
    localparam FIELDS = 3'd3;
    localparam COMPLETE = 3'd4;
    
    reg [7:0] desc_length;
    reg [7:0] desc_type;
    reg [7:0] byte_count;
    reg [7:0] field_position;
    
    // 添加数据缓冲寄存器以减少data_in的扇出负载
    reg [7:0] data_in_buf1;
    reg [7:0] data_in_buf2;
    
    // 控制信号缓冲
    reg data_valid_buf;
    reg start_parse_buf;
    
    // 输入信号缓冲 - 将data_in和控制信号进行缓冲处理
    always @(posedge clk) begin
        data_in_buf1 <= data_in;
        data_in_buf2 <= data_in;
        data_valid_buf <= data_valid;
        start_parse_buf <= start_parse;
    end
    
    // 状态转换逻辑
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            parse_state <= IDLE;
            parsing_complete <= 1'b0;
        end else begin
            case (parse_state)
                IDLE: begin
                    if (start_parse_buf && data_valid_buf) begin
                        parse_state <= LENGTH;
                    end
                    parsing_complete <= 1'b0;
                end
                LENGTH: begin
                    if (data_valid_buf) begin
                        parse_state <= TYPE;
                    end
                end
                TYPE: begin
                    if (data_valid_buf) begin
                        parse_state <= FIELDS;
                    end
                end
                FIELDS: begin
                    if (byte_count >= desc_length - 1) begin
                        parse_state <= COMPLETE;
                    end
                end
                COMPLETE: begin
                    parse_state <= IDLE;
                    parsing_complete <= 1'b1;
                end
                default: parse_state <= IDLE;
            endcase
        end
    end
    
    // 字节计数器逻辑
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            byte_count <= 8'd0;
        end else if (parse_state == IDLE && start_parse_buf && data_valid_buf) begin
            byte_count <= 8'd1;
        end else if (data_valid_buf && (parse_state != IDLE && parse_state != COMPLETE)) begin
            byte_count <= byte_count + 8'd1;
        end else if (parse_state == COMPLETE) begin
            byte_count <= 8'd0;
        end
    end
    
    // 字段位置逻辑
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            field_position <= 8'd0;
        end else if (parse_state == LENGTH && data_valid_buf) begin
            field_position <= 8'd0;
        end else if (parse_state == FIELDS && data_valid_buf) begin
            field_position <= field_position + 8'd1;
        end
    end
    
    // 描述符长度和类型处理
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            desc_length <= 8'd0;
            desc_type <= 8'd0;
        end else if (parse_state == IDLE && start_parse_buf && data_valid_buf) begin
            desc_length <= data_in_buf1;
        end else if (parse_state == LENGTH && data_valid_buf) begin
            desc_type <= data_in_buf2;
        end
    end
    
    // 设备信息处理 - 第一部分
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            vendor_id <= 16'h0000;
            product_id <= 16'h0000;
        end else if (parse_state == FIELDS && data_valid_buf) begin
            case (field_position)
                8'd6: vendor_id[7:0] <= data_in_buf1;
                8'd7: vendor_id[15:8] <= data_in_buf1;
                8'd8: product_id[7:0] <= data_in_buf2;
                8'd9: product_id[15:8] <= data_in_buf2;
                default: begin end
            endcase
        end
    end
    
    // 设备信息处理 - 第二部分
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            device_class <= 8'h00;
            max_packet_size <= 8'h00;
            num_configurations <= 8'h00;
        end else if (parse_state == FIELDS && data_valid_buf) begin
            case (field_position)
                8'd4: device_class <= data_in_buf1;
                8'd7: max_packet_size <= data_in_buf2;
                8'd17: num_configurations <= data_in_buf1;
                default: begin end
            endcase
        end
    end
endmodule