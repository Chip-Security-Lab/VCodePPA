//SystemVerilog
`timescale 1ns / 1ps
module i2c_codec (
    input wire clk, rstn, 
    input wire start_xfer, rw,
    input wire [6:0] addr,
    input wire [7:0] wr_data,
    inout wire sda,
    output reg scl,
    output reg [7:0] rd_data,
    output reg busy, done
);
    localparam IDLE=0, START=1, ADDR=2, RW=3, ACK1=4, DATA=5, ACK2=6, STOP=7;
    reg [2:0] state, next;
    reg [3:0] bit_cnt;
    reg [7:0] shift_reg;
    reg sda_out, sda_oe;
    
    // 时钟分频计数器
    reg [1:0] clk_div;
    wire scl_toggle = (clk_div == 2'b10);
    wire sample_point = (clk_div == 2'b01) && (scl == 1'b1);
    wire setup_point = (clk_div == 2'b11) && (scl == 1'b0);
    
    // 寄存 输入信号
    reg start_xfer_reg, rw_reg;
    reg [6:0] addr_reg;
    reg [7:0] wr_data_reg;
    
    assign sda = sda_oe ? sda_out : 1'bz;
    
    // 输入信号寄存逻辑
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            start_xfer_reg <= 1'b0;
            rw_reg <= 1'b0;
            addr_reg <= 7'h0;
            wr_data_reg <= 8'h0;
        end
        else begin
            start_xfer_reg <= start_xfer;
            rw_reg <= rw;
            addr_reg <= addr;
            wr_data_reg <= wr_data;
        end
    end
    
    // 时钟分频逻辑
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            clk_div <= 2'b00;
        else if (state == IDLE)
            clk_div <= 2'b00;
        else
            clk_div <= cla_adder_2bit(clk_div, 2'b01); // 使用先行进位加法器
    end
    
    // SCL生成逻辑
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            scl <= 1'b1;
        else if (state == IDLE || state == START || state == STOP)
            scl <= 1'b1;
        else if (scl_toggle)
            scl <= ~scl;
    end
    
    // 状态寄存器
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin 
            state <= IDLE; 
            bit_cnt <= 0; 
            busy <= 1'b0;
            done <= 1'b0;
        end
        else begin
            state <= next;
            
            if (state == IDLE) begin
                bit_cnt <= 0;
                busy <= start_xfer_reg;
                done <= 1'b0;
            end
            else if (state == STOP) begin
                busy <= 1'b0;
                done <= 1'b1;
            end
            else if ((state == ADDR || state == DATA) && scl_toggle && scl == 1'b0) begin
                bit_cnt <= cla_adder_4bit(bit_cnt, 4'b0001); // 使用先行进位加法器
            end
            else if (state == ACK1 || state == ACK2) begin
                bit_cnt <= 0;
            end
        end
    end
    
    // 状态机转移逻辑
    always @(*) begin
        next = state;
        
        case (state)
            IDLE: begin
                if (start_xfer_reg) next = START;
            end
            
            START: begin
                if (setup_point) next = ADDR;
            end
            
            ADDR: begin
                if (bit_cnt == 7 && scl_toggle && scl == 1'b0) next = RW;
            end
            
            RW: begin
                if (scl_toggle && scl == 1'b0) next = ACK1;
            end
            
            ACK1: begin
                if (scl_toggle && scl == 1'b0) begin
                    if (sda == 1'b0) // ACK received
                        next = DATA;
                    else // NACK received
                        next = STOP;
                end
            end
            
            DATA: begin
                if (bit_cnt == 8 && scl_toggle && scl == 1'b0) next = ACK2;
            end
            
            ACK2: begin
                if (scl_toggle && scl == 1'b0) begin
                    if (rw_reg || sda == 1'b0) // Read or ACK received
                        next = STOP;
                    else // NACK received in write mode
                        next = STOP;
                end
            end
            
            STOP: begin
                if (setup_point) next = IDLE;
            end
            
            default: next = IDLE;
        endcase
    end
    
    // SDA控制逻辑
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            sda_out <= 1'b1;
            sda_oe <= 1'b1;
            shift_reg <= 8'h00;
            rd_data <= 8'h00;
        end
        else begin
            case (state)
                IDLE: begin
                    sda_out <= 1'b1;
                    sda_oe <= 1'b1;
                    if (start_xfer_reg) begin
                        shift_reg <= {addr_reg, rw_reg};
                    end
                end
                
                START: begin
                    if (clk_div == 2'b01) sda_out <= 1'b0; // START条件：SCL高时SDA从高到低
                    sda_oe <= 1'b1;
                end
                
                ADDR: begin
                    sda_out <= shift_reg[7];
                    sda_oe <= 1'b1;
                    if (scl_toggle && scl == 1'b0) begin
                        shift_reg <= {shift_reg[6:0], 1'b0};
                    end
                end
                
                RW: begin
                    sda_out <= rw_reg;
                    sda_oe <= 1'b1;
                    if (rw_reg && scl_toggle && scl == 1'b0) begin
                        shift_reg <= 8'h00; // 准备读数据
                    end
                    else if (!rw_reg && scl_toggle && scl == 1'b0) begin
                        shift_reg <= wr_data_reg; // 准备写数据
                    end
                end
                
                ACK1: begin
                    sda_oe <= 1'b0; // 释放SDA总线接收ACK
                end
                
                DATA: begin
                    if (rw_reg) begin // 读操作
                        sda_oe <= 1'b0; // 释放SDA总线
                        if (sample_point) begin
                            shift_reg <= {shift_reg[6:0], sda};
                        end
                    end
                    else begin // 写操作
                        sda_out <= shift_reg[7];
                        sda_oe <= 1'b1;
                        if (scl_toggle && scl == 1'b0) begin
                            shift_reg <= {shift_reg[6:0], 1'b0};
                        end
                    end
                end
                
                ACK2: begin
                    if (rw_reg) begin // 读操作
                        sda_out <= 1'b1; // 发送NACK表示结束传输
                        sda_oe <= 1'b1;
                        rd_data <= shift_reg; // 保存读取的数据
                    end
                    else begin // 写操作
                        sda_oe <= 1'b0; // 释放SDA总线接收ACK
                    end
                end
                
                STOP: begin
                    sda_out <= 1'b0;
                    sda_oe <= 1'b1;
                    if (clk_div == 2'b11) sda_out <= 1'b1; // STOP条件：SCL高时SDA从低到高
                end
            endcase
        end
    end
    
    // 先行进位加法器实现 - 2位版本
    function [1:0] cla_adder_2bit;
        input [1:0] a, b;
        reg [1:0] sum;
        reg [1:0] p, g; // 进位传递与生成信号
        reg [1:0] c; // 进位信号
        begin
            // 计算传递和生成信号
            p[0] = a[0] ^ b[0];
            g[0] = a[0] & b[0];
            p[1] = a[1] ^ b[1];
            g[1] = a[1] & b[1];
            
            // 计算进位信号
            c[0] = 1'b0; // 初始进位为0
            c[1] = g[0] | (p[0] & c[0]);
            
            // 计算和
            sum[0] = p[0] ^ c[0];
            sum[1] = p[1] ^ c[1];
            
            cla_adder_2bit = sum;
        end
    endfunction
    
    // 先行进位加法器实现 - 4位版本
    function [3:0] cla_adder_4bit;
        input [3:0] a, b;
        reg [3:0] sum;
        reg [3:0] p, g; // 进位传递与生成信号
        reg [4:0] c; // 进位信号
        begin
            // 计算传递和生成信号
            p[0] = a[0] ^ b[0];
            g[0] = a[0] & b[0];
            p[1] = a[1] ^ b[1];
            g[1] = a[1] & b[1];
            p[2] = a[2] ^ b[2];
            g[2] = a[2] & b[2];
            p[3] = a[3] ^ b[3];
            g[3] = a[3] & b[3];
            
            // 计算进位信号
            c[0] = 1'b0; // 初始进位为0
            c[1] = g[0] | (p[0] & c[0]);
            c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
            c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
            c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
            
            // 计算和
            sum[0] = p[0] ^ c[0];
            sum[1] = p[1] ^ c[1];
            sum[2] = p[2] ^ c[2];
            sum[3] = p[3] ^ c[3];
            
            cla_adder_4bit = sum;
        end
    endfunction
    
endmodule