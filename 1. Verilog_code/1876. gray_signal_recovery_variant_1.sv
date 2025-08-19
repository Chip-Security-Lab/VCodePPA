//SystemVerilog
module gray_signal_recovery_axi_lite (
    input                   clk,
    input                   rst_n,
    
    // AXI4-Lite写地址通道
    input                   s_axil_awvalid,
    output reg              s_axil_awready,
    input [7:0]             s_axil_awaddr,
    
    // AXI4-Lite写数据通道
    input                   s_axil_wvalid,
    output reg              s_axil_wready,
    input [31:0]            s_axil_wdata,
    input [3:0]             s_axil_wstrb,
    
    // AXI4-Lite写响应通道
    output reg              s_axil_bvalid,
    input                   s_axil_bready,
    output reg [1:0]        s_axil_bresp,
    
    // AXI4-Lite读地址通道
    input                   s_axil_arvalid,
    output reg              s_axil_arready,
    input [7:0]             s_axil_araddr,
    
    // AXI4-Lite读数据通道
    output reg              s_axil_rvalid,
    input                   s_axil_rready,
    output reg [31:0]       s_axil_rdata,
    output reg [1:0]        s_axil_rresp
);
    // 内部寄存器
    reg [3:0]  input_gray_data;
    reg [3:0]  prev_gray;
    reg [3:0]  decoded_reg;
    reg [3:0]  output_data;
    reg        data_valid;
    reg        process_trigger;
    
    // 状态寄存器地址映射
    localparam ADDR_CONTROL     = 8'h00;  // 控制寄存器
    localparam ADDR_STATUS      = 8'h04;  // 状态寄存器
    localparam ADDR_INPUT_DATA  = 8'h08;  // 输入数据寄存器
    localparam ADDR_OUTPUT_DATA = 8'h0C;  // 输出数据寄存器
    
    // 解码电路
    wire [3:0] decoded;
    assign decoded[3] = input_gray_data[3];
    assign decoded[2] = decoded[3] ^ input_gray_data[2];
    assign decoded[1] = decoded[2] ^ input_gray_data[1];
    assign decoded[0] = decoded[1] ^ input_gray_data[0];
    
    // AXI4-Lite 写事务处理
    reg write_addr_valid;
    reg [7:0] write_addr;
    
    // 写地址通道处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_awready <= 1'b1;
            write_addr_valid <= 1'b0;
            write_addr <= 8'h0;
        end else begin
            if (s_axil_awvalid && s_axil_awready) begin
                write_addr <= s_axil_awaddr;
                write_addr_valid <= 1'b1;
                s_axil_awready <= 1'b0;
            end else if (write_addr_valid && s_axil_wvalid && s_axil_wready && s_axil_bvalid && s_axil_bready) begin
                write_addr_valid <= 1'b0;
                s_axil_awready <= 1'b1;
            end
        end
    end
    
    // 写数据通道处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_wready <= 1'b1;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
            input_gray_data <= 4'b0;
            process_trigger <= 1'b0;
        end else begin
            process_trigger <= 1'b0;
            
            if (write_addr_valid && s_axil_wvalid && s_axil_wready) begin
                s_axil_wready <= 1'b0;
                s_axil_bvalid <= 1'b1;
                s_axil_bresp <= 2'b00; // OKAY
                
                case (write_addr)
                    ADDR_CONTROL: begin
                        // 控制寄存器，此处可以添加更多控制功能
                        process_trigger <= s_axil_wdata[0];
                    end
                    
                    ADDR_INPUT_DATA: begin
                        if (s_axil_wstrb[0]) begin
                            input_gray_data <= s_axil_wdata[3:0];
                            process_trigger <= 1'b1;
                        end
                    end
                    
                    default: s_axil_bresp <= 2'b10; // SLVERR
                endcase
            end
            
            if (s_axil_bvalid && s_axil_bready) begin
                s_axil_bvalid <= 1'b0;
                s_axil_wready <= 1'b1;
            end
        end
    end
    
    // AXI4-Lite 读事务处理
    reg read_addr_valid;
    reg [7:0] read_addr;
    
    // 读地址通道处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_arready <= 1'b1;
            read_addr_valid <= 1'b0;
            read_addr <= 8'h0;
        end else begin
            if (s_axil_arvalid && s_axil_arready) begin
                read_addr <= s_axil_araddr;
                read_addr_valid <= 1'b1;
                s_axil_arready <= 1'b0;
            end else if (read_addr_valid && s_axil_rvalid && s_axil_rready) begin
                read_addr_valid <= 1'b0;
                s_axil_arready <= 1'b1;
            end
        end
    end
    
    // 读数据通道处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_rvalid <= 1'b0;
            s_axil_rdata <= 32'h0;
            s_axil_rresp <= 2'b00;
        end else begin
            if (read_addr_valid && !s_axil_rvalid) begin
                s_axil_rvalid <= 1'b1;
                s_axil_rresp <= 2'b00; // OKAY
                
                case (read_addr)
                    ADDR_STATUS: begin
                        s_axil_rdata <= {31'h0, data_valid};
                    end
                    
                    ADDR_INPUT_DATA: begin
                        s_axil_rdata <= {28'h0, input_gray_data};
                    end
                    
                    ADDR_OUTPUT_DATA: begin
                        s_axil_rdata <= {28'h0, output_data};
                    end
                    
                    default: begin
                        s_axil_rdata <= 32'h0;
                        s_axil_rresp <= 2'b10; // SLVERR
                    end
                endcase
            end
            
            if (s_axil_rvalid && s_axil_rready) begin
                s_axil_rvalid <= 1'b0;
            end
        end
    end
    
    // 核心处理逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_gray <= 4'b0;
            decoded_reg <= 4'b0;
            data_valid <= 1'b0;
            output_data <= 4'b0;
        end else begin
            if (process_trigger) begin
                decoded_reg <= decoded;
                prev_gray <= input_gray_data;
                data_valid <= (prev_gray != input_gray_data);
            end
            
            if (data_valid) begin
                output_data <= decoded_reg;
                data_valid <= 1'b0;
            end
        end
    end
endmodule