//SystemVerilog
module Matrix_AND (
    input wire s_axi_aclk,
    input wire s_axi_aresetn,
    
    // AXI4-Lite写地址通道
    input wire [31:0] s_axi_awaddr,
    input wire s_axi_awvalid,
    output reg s_axi_awready,
    
    // AXI4-Lite写数据通道
    input wire [31:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output reg s_axi_wready,
    
    // AXI4-Lite写响应通道
    output reg [1:0] s_axi_bresp,
    output reg s_axi_bvalid,
    input wire s_axi_bready,
    
    // AXI4-Lite读地址通道
    input wire [31:0] s_axi_araddr,
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    
    // AXI4-Lite读数据通道
    output reg [31:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid,
    input wire s_axi_rready,
    
    // 输出结果
    output wire [7:0] matrix_res
);
    // 内部寄存器定义
    reg [3:0] row_reg;
    reg [3:0] col_reg;
    
    // 内部信号定义
    wire [7:0] combined_input;
    wire [7:0] mask_pattern;
    
    // AXI4-Lite状态机状态
    localparam IDLE = 2'b00;
    localparam ADDR = 2'b01;
    localparam DATA = 2'b10;
    localparam RESP = 2'b11;
    
    // AXI4-Lite写状态机
    reg [1:0] write_state;
    reg [1:0] write_next;
    reg [31:0] write_addr;
    
    // AXI4-Lite读状态机
    reg [1:0] read_state;
    reg [1:0] read_next;
    reg [31:0] read_addr;
    
    // 寄存器地址映射
    localparam ROW_ADDR = 32'h0000_0000;
    localparam COL_ADDR = 32'h0000_0004;
    localparam RESULT_ADDR = 32'h0000_0008;
    
    // 写状态机
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            write_state <= IDLE;
            write_addr <= 32'h0;
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;
            row_reg <= 4'h0;
            col_reg <= 4'h0;
        end else begin
            case (write_state)
                IDLE: begin
                    s_axi_awready <= 1'b1;
                    s_axi_wready <= 1'b0;
                    s_axi_bvalid <= 1'b0;
                    
                    if (s_axi_awvalid && s_axi_awready) begin
                        write_addr <= s_axi_awaddr;
                        s_axi_awready <= 1'b0;
                        s_axi_wready <= 1'b1;
                        write_state <= DATA;
                    end
                end
                
                DATA: begin
                    if (s_axi_wvalid && s_axi_wready) begin
                        s_axi_wready <= 1'b0;
                        s_axi_bvalid <= 1'b1;
                        s_axi_bresp <= 2'b00; // OKAY
                        
                        // 写入相应的寄存器
                        case (write_addr)
                            ROW_ADDR: row_reg <= s_axi_wdata[3:0];
                            COL_ADDR: col_reg <= s_axi_wdata[3:0];
                            default: ; // 其他地址不做处理
                        endcase
                        
                        write_state <= RESP;
                    end
                end
                
                RESP: begin
                    if (s_axi_bready && s_axi_bvalid) begin
                        s_axi_bvalid <= 1'b0;
                        write_state <= IDLE;
                    end
                end
                
                default: write_state <= IDLE;
            endcase
        end
    end
    
    // 读状态机
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            read_state <= IDLE;
            read_addr <= 32'h0;
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= 2'b00;
            s_axi_rdata <= 32'h0;
        end else begin
            case (read_state)
                IDLE: begin
                    s_axi_arready <= 1'b1;
                    s_axi_rvalid <= 1'b0;
                    
                    if (s_axi_arvalid && s_axi_arready) begin
                        read_addr <= s_axi_araddr;
                        s_axi_arready <= 1'b0;
                        read_state <= DATA;
                    end
                end
                
                DATA: begin
                    s_axi_rvalid <= 1'b1;
                    s_axi_rresp <= 2'b00; // OKAY
                    
                    // 读取相应的寄存器
                    case (read_addr)
                        ROW_ADDR: s_axi_rdata <= {28'h0, row_reg};
                        COL_ADDR: s_axi_rdata <= {28'h0, col_reg};
                        RESULT_ADDR: s_axi_rdata <= {24'h0, matrix_res};
                        default: s_axi_rdata <= 32'h0;
                    endcase
                    
                    read_state <= RESP;
                end
                
                RESP: begin
                    if (s_axi_rready && s_axi_rvalid) begin
                        s_axi_rvalid <= 1'b0;
                        read_state <= IDLE;
                    end
                end
                
                default: read_state <= IDLE;
            endcase
        end
    end
    
    // 实例化子模块
    InputCombiner input_combiner (
        .row(row_reg),
        .col(col_reg),
        .combined(combined_input)
    );
    
    MaskGenerator mask_gen (
        .mask(mask_pattern)
    );
    
    BitwiseOperator bit_operator (
        .data_in(combined_input),
        .mask(mask_pattern),
        .data_out(matrix_res)
    );
    
endmodule

// 输入组合子模块
module InputCombiner (
    input [3:0] row,
    input [3:0] col,
    output [7:0] combined
);
    // 组合输入行和列
    assign combined = {row, col};
endmodule

// 掩码生成子模块
module MaskGenerator (
    output [7:0] mask
);
    // 生成固定掩码模式
    assign mask = 8'h55; // 01010101
endmodule

// 位操作子模块
module BitwiseOperator (
    input [7:0] data_in,
    input [7:0] mask,
    output [7:0] data_out
);
    // 执行位与操作
    assign data_out = data_in & mask;
endmodule