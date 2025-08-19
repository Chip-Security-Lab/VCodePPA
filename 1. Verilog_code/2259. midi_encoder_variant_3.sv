//SystemVerilog
`timescale 1ns / 1ps
module midi_encoder (
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    // AXI4-Lite写地址通道
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    // AXI4-Lite写数据通道
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    // AXI4-Lite写响应通道
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    // AXI4-Lite读地址通道
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    // AXI4-Lite读数据通道
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    // MIDI输出
    output reg  [7:0]  tx_byte
);

    // 寄存器地址
    localparam ADDR_CONTROL    = 4'h0;  // 控制寄存器: note_on位
    localparam ADDR_NOTE       = 4'h4;  // 音符寄存器
    localparam ADDR_VELOCITY   = 4'h8;  // 力度寄存器
    localparam ADDR_STATUS     = 4'hC;  // 状态寄存器
    
    // AXI响应代码
    localparam RESP_OKAY       = 2'b00;
    localparam RESP_SLVERR     = 2'b10;
    
    // 内部寄存器
    reg        note_on_reg;
    reg [6:0]  note_reg;
    reg [6:0]  velocity_reg;
    reg [1:0]  state;
    reg [1:0]  next_state;
    
    // 写寄存器逻辑
    reg        wr_en;
    reg [3:0]  wr_addr;
    reg [31:0] wr_data;
    
    // 读寄存器逻辑
    reg        rd_en;
    reg [3:0]  rd_addr;
    
    // AXI4-Lite写地址握手
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            wr_addr <= 4'h0;
        end 
        else begin
            if (~s_axi_awready && s_axi_awvalid && s_axi_wvalid && (s_axi_bready || ~s_axi_bvalid)) begin
                s_axi_awready <= 1'b1;
                wr_addr <= s_axi_awaddr[5:2];  // 获取地址的字节偏移
            end 
            else begin
                s_axi_awready <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite写数据握手
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_wready <= 1'b0;
            wr_en <= 1'b0;
            wr_data <= 32'h0;
        end 
        else begin
            if (~s_axi_wready && s_axi_wvalid && s_axi_awvalid && (s_axi_bready || ~s_axi_bvalid)) begin
                s_axi_wready <= 1'b1;
                wr_en <= 1'b1;
                wr_data <= s_axi_wdata;
            end 
            else begin
                s_axi_wready <= 1'b0;
                wr_en <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite写响应通道
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= RESP_OKAY;
        end 
        else begin
            if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid && ~s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp <= RESP_OKAY;  // 总是返回OKAY
            end 
            else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite读地址握手
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
            rd_addr <= 4'h0;
            rd_en <= 1'b0;
        end 
        else begin
            if (~s_axi_arready && s_axi_arvalid && (~s_axi_rvalid || s_axi_rready)) begin
                s_axi_arready <= 1'b1;
                rd_addr <= s_axi_araddr[5:2];  // 获取地址的字节偏移
                rd_en <= 1'b1;
            end 
            else begin
                s_axi_arready <= 1'b0;
                rd_en <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite读数据响应
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= RESP_OKAY;
            s_axi_rdata <= 32'h0;
        end 
        else begin
            if (s_axi_arready && s_axi_arvalid && ~s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp <= RESP_OKAY;  // 总是返回OKAY
                
                case (rd_addr)
                    ADDR_CONTROL[3:0]:  s_axi_rdata <= {31'b0, note_on_reg};
                    ADDR_NOTE[3:0]:     s_axi_rdata <= {25'b0, note_reg};
                    ADDR_VELOCITY[3:0]: s_axi_rdata <= {25'b0, velocity_reg};
                    ADDR_STATUS[3:0]:   s_axi_rdata <= {30'b0, state};
                    default:            s_axi_rdata <= 32'h0;
                endcase
            end 
            else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end
    
    // 处理写寄存器更新
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            note_on_reg <= 1'b0;
            note_reg <= 7'h0;
            velocity_reg <= 7'h0;
        end 
        else if (wr_en) begin
            case (wr_addr)
                ADDR_CONTROL[3:0]:  note_on_reg <= s_axi_wdata[0];
                ADDR_NOTE[3:0]:     note_reg <= s_axi_wdata[6:0];
                ADDR_VELOCITY[3:0]: velocity_reg <= s_axi_wdata[6:0];
                default: begin end  // 无操作
            endcase
        end
    end
    
    // MIDI状态机逻辑
    // 下一状态逻辑（组合）
    always @(*) begin
        next_state = state;
        case(state)
            2'd0: if(note_on_reg) next_state = 2'd1;
            2'd1: next_state = 2'd2;
            2'd2: next_state = 2'd0;
            default: next_state = 2'd0;
        endcase
    end
    
    // 状态寄存器更新
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            state <= 2'd0;
        end 
        else begin
            state <= next_state;
        end
    end
    
    // 输出逻辑
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            tx_byte <= 8'h0;
        end 
        else begin
            case(state)
                2'd0: begin
                    if(note_on_reg) begin
                        tx_byte <= 8'h90;
                    end
                end
                2'd1: begin
                    tx_byte <= {1'b0, note_reg};
                end
                2'd2: begin
                    tx_byte <= {1'b0, velocity_reg};
                end
                default: tx_byte <= tx_byte;
            endcase
        end
    end

endmodule