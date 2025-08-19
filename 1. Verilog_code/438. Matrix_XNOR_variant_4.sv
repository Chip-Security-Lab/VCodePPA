//SystemVerilog
module Matrix_XNOR_AXI (
    // 时钟和复位信号
    input wire aclk,
    input wire aresetn,
    
    // AXI4-Lite 写地址通道
    input wire [31:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // AXI4-Lite 写数据通道
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // AXI4-Lite 写响应通道
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // AXI4-Lite 读地址通道
    input wire [31:0] s_axil_araddr,
    input wire [2:0] s_axil_arprot,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // AXI4-Lite 读数据通道
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready
);

    // 内部寄存器
    reg [3:0] row_reg;
    reg [3:0] col_reg;
    reg [7:0] mat_res_reg; // 已将组合逻辑的结果移到寄存器中
    wire [7:0] mat_res_wire;
    
    // 寄存器地址映射 (字对齐)
    localparam ADDR_ROW = 4'h0;       // 地址 0x0: row 寄存器
    localparam ADDR_COL = 4'h4;       // 地址 0x4: col 寄存器
    localparam ADDR_RESULT = 4'h8;    // 地址 0x8: 结果寄存器
    
    // 优化后的XNOR功能实现 - 将组合逻辑结果寄存
    assign mat_res_wire = ~({row_reg, col_reg} ^ 8'h55);
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            mat_res_reg <= 8'h0;
        end else begin
            mat_res_reg <= mat_res_wire;
        end
    end
    
    // AXI4-Lite 写通道状态机
    reg [1:0] write_state;
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    
    reg [31:0] write_addr;
    reg write_resp_valid;
    reg [1:0] write_resp_value;
    reg [3:0] row_next, col_next;
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            row_reg <= 4'h0;
            col_reg <= 4'h0;
        end else begin
            if (write_resp_valid) begin
                row_reg <= row_next;
                col_reg <= col_next;
            end
        end
    end
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            write_state <= WRITE_IDLE;
            write_addr <= 32'h0;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
            write_resp_valid <= 1'b0;
            write_resp_value <= 2'b00;
            row_next <= 4'h0;
            col_next <= 4'h0;
        end else begin
            write_resp_valid <= 1'b0;
            
            case (write_state)
                WRITE_IDLE: begin
                    s_axil_awready <= 1'b1;
                    s_axil_wready <= 1'b0;
                    s_axil_bvalid <= 1'b0;
                    
                    if (s_axil_awvalid && s_axil_awready) begin
                        write_addr <= s_axil_awaddr;
                        s_axil_awready <= 1'b0;
                        s_axil_wready <= 1'b1;
                        write_state <= WRITE_DATA;
                    end
                end
                
                WRITE_DATA: begin
                    if (s_axil_wvalid && s_axil_wready) begin
                        s_axil_wready <= 1'b0;
                        s_axil_bvalid <= 1'b1;
                        write_resp_value <= 2'b00; // OKAY
                        
                        // 根据地址准备写入值
                        row_next <= row_reg;
                        col_next <= col_reg;
                        
                        case (write_addr[3:0])
                            ADDR_ROW: row_next <= s_axil_wdata[3:0];
                            ADDR_COL: col_next <= s_axil_wdata[3:0];
                            default: write_resp_value <= 2'b10; // SLVERR - 无效地址
                        endcase
                        
                        write_resp_valid <= 1'b1;
                        s_axil_bresp <= write_resp_value;
                        write_state <= WRITE_RESP;
                    end
                end
                
                WRITE_RESP: begin
                    if (s_axil_bready && s_axil_bvalid) begin
                        s_axil_bvalid <= 1'b0;
                        write_state <= WRITE_IDLE;
                    end
                end
                
                default: write_state <= WRITE_IDLE;
            endcase
        end
    end
    
    // AXI4-Lite 读通道状态机
    reg [1:0] read_state;
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;
    
    reg [31:0] read_addr;
    reg [31:0] read_data_reg;
    reg [1:0] read_resp_reg;
    reg read_data_valid;
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            read_data_reg <= 32'h0;
            read_resp_reg <= 2'b00;
            s_axil_rdata <= 32'h0;
            s_axil_rresp <= 2'b00;
        end else begin
            if (read_data_valid) begin
                s_axil_rdata <= read_data_reg;
                s_axil_rresp <= read_resp_reg;
            end
        end
    end
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            read_state <= READ_IDLE;
            read_addr <= 32'h0;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            read_data_valid <= 1'b0;
        end else begin
            read_data_valid <= 1'b0;
            
            case (read_state)
                READ_IDLE: begin
                    s_axil_arready <= 1'b1;
                    s_axil_rvalid <= 1'b0;
                    
                    if (s_axil_arvalid && s_axil_arready) begin
                        read_addr <= s_axil_araddr;
                        s_axil_arready <= 1'b0;
                        read_state <= READ_DATA;
                    end
                end
                
                READ_DATA: begin
                    s_axil_rvalid <= 1'b1;
                    read_resp_reg <= 2'b00; // OKAY
                    
                    // 根据地址准备读取数据
                    case (read_addr[3:0])
                        ADDR_ROW: read_data_reg <= {28'h0, row_reg};
                        ADDR_COL: read_data_reg <= {28'h0, col_reg};
                        ADDR_RESULT: read_data_reg <= {24'h0, mat_res_reg};
                        default: begin
                            read_data_reg <= 32'h0;
                            read_resp_reg <= 2'b10; // SLVERR - 无效地址
                        end
                    endcase
                    
                    read_data_valid <= 1'b1;
                    
                    if (s_axil_rready && s_axil_rvalid) begin
                        s_axil_rvalid <= 1'b0;
                        read_state <= READ_IDLE;
                    end
                end
                
                default: read_state <= READ_IDLE;
            endcase
        end
    end

endmodule