module CAN_Multi_Mailbox #(
    parameter NUM_MAILBOXES = 4,
    parameter DATA_WIDTH = 8
)(
    input clk,
    input rst_n,
    input can_rx,
    output reg can_tx,
    input [DATA_WIDTH-1:0] tx_data [0:NUM_MAILBOXES-1],
    output [DATA_WIDTH-1:0] rx_data [0:NUM_MAILBOXES-1],
    input [NUM_MAILBOXES-1:0] tx_request,
    output reg [NUM_MAILBOXES-1:0] tx_complete
);
    // 添加缺少的信号
    reg can_tx_ack;
    reg [1:0] mailbox_select;
    reg [NUM_MAILBOXES-1:0] tx_active_array;
    
    // 修复数组类型声明
    reg [DATA_WIDTH-1:0] tx_reg_array [0:NUM_MAILBOXES-1];
    reg [DATA_WIDTH-1:0] rx_reg_array [0:NUM_MAILBOXES-1];
    
    // 邮箱逻辑
    genvar i;
    generate
        for (i=0; i<NUM_MAILBOXES; i=i+1) begin : mailbox_gen
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    tx_reg_array[i] <= 0;
                    rx_reg_array[i] <= 0;
                    tx_active_array[i] <= 0;
                    tx_complete[i] <= 0;
                end else begin
                    if (tx_request[i]) begin
                        tx_reg_array[i] <= tx_data[i];
                        tx_active_array[i] <= 1'b1;
                    end else if (can_tx_ack && tx_active_array[i]) begin
                        tx_active_array[i] <= 1'b0;
                        tx_complete[i] <= 1'b1;
                    end else begin
                        tx_complete[i] <= 1'b0;
                    end
                    
                    // 当选择此邮箱时接收数据
                    if (mailbox_select == i) begin
                        rx_reg_array[i] <= {rx_reg_array[i][DATA_WIDTH-2:0], can_rx};
                    end
                end
            end
            
            // 给此邮箱赋值rx_data
            assign rx_data[i] = rx_reg_array[i];
        end
    endgenerate
    
    // 简单仲裁和数据多路复用逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mailbox_select <= 0;
            can_tx <= 1'b1;
            can_tx_ack <= 1'b0;
        end else begin
            // 轮询邮箱选择
            if (!(&tx_active_array)) begin
                mailbox_select <= mailbox_select + 1;
                if (mailbox_select >= NUM_MAILBOXES-1)
                    mailbox_select <= 0;
            end
            
            // 发送选择邮箱数据
            can_tx <= tx_reg_array[mailbox_select][DATA_WIDTH-1];
            
            // 发送确认模拟
            can_tx_ack <= (mailbox_select == 0);
        end
    end
endmodule