//SystemVerilog
// SystemVerilog
module cam_4 (
    input wire clk,
    input wire rst,
    
    // AXI4-Lite Slave Interface
    // Write Address Channel
    input wire [31:0] s_axil_awaddr,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // Write Data Channel
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // Write Response Channel
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // Read Address Channel
    input wire [31:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // Read Data Channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready,
    
    // Original module output
    output reg match_flag
);

    // 内部寄存器
    reg [7:0] data_a, data_b;
    reg [7:0] compare_data;  // 用于存储比较数据
    
    // 优化的比较结果存储
    reg match_a, match_b;
    
    // AXI4-Lite 地址解码常量定义
    localparam ADDR_DATA_A = 4'h0;       // 地址 0x00: data_a
    localparam ADDR_DATA_B = 4'h4;       // 地址 0x04: data_b
    localparam ADDR_COMPARE = 4'h8;      // 地址 0x08: compare_data
    localparam ADDR_MATCH_FLAG = 4'hC;   // 地址 0x0C: match_flag (只读)
    
    // AXI 状态定义
    localparam RESP_OKAY = 2'b00;
    localparam RESP_SLVERR = 2'b10;
    
    // 写请求状态机优化：使用独热编码
    localparam WRITE_IDLE = 3'b001;
    localparam WRITE_DATA = 3'b010;
    localparam WRITE_RESP = 3'b100;
    reg [2:0] write_state;
    
    // 读请求状态机优化：使用独热编码
    localparam READ_IDLE = 2'b01;
    localparam READ_DATA = 2'b10;
    reg [1:0] read_state;
    
    // 写地址暂存 - 使用地址解码而不是直接存储
    reg write_to_data_a;
    reg write_to_data_b;
    reg write_to_compare;
    reg address_error;
    
    // 写通道状态机
    always @(posedge clk) begin
        if (rst) begin
            write_state <= WRITE_IDLE;
            s_axil_awready <= 1'b1;
            s_axil_wready <= 1'b0;
            s_axil_bresp <= RESP_OKAY;
            s_axil_bvalid <= 1'b0;
            write_to_data_a <= 1'b0;
            write_to_data_b <= 1'b0;
            write_to_compare <= 1'b0;
            address_error <= 1'b0;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    s_axil_bvalid <= 1'b0;
                    if (s_axil_awvalid && s_axil_awready) begin
                        // 直接解码地址，减少延迟
                        write_to_data_a <= (s_axil_awaddr[3:0] == ADDR_DATA_A);
                        write_to_data_b <= (s_axil_awaddr[3:0] == ADDR_DATA_B);
                        write_to_compare <= (s_axil_awaddr[3:0] == ADDR_COMPARE);
                        address_error <= ~((s_axil_awaddr[3:0] == ADDR_DATA_A) || 
                                          (s_axil_awaddr[3:0] == ADDR_DATA_B) || 
                                          (s_axil_awaddr[3:0] == ADDR_COMPARE));
                        
                        s_axil_awready <= 1'b0;
                        s_axil_wready <= 1'b1;
                        write_state <= WRITE_DATA;
                    end
                end
                
                WRITE_DATA: begin
                    if (s_axil_wvalid && s_axil_wready) begin
                        s_axil_wready <= 1'b0;
                        s_axil_bresp <= address_error ? RESP_SLVERR : RESP_OKAY;
                        s_axil_bvalid <= 1'b1;
                        
                        // 根据解码后的信号写入对应寄存器
                        if (write_to_data_a) data_a <= s_axil_wdata[7:0];
                        if (write_to_data_b) data_b <= s_axil_wdata[7:0];
                        if (write_to_compare) compare_data <= s_axil_wdata[7:0];
                        
                        write_state <= WRITE_RESP;
                    end
                end
                
                WRITE_RESP: begin
                    if (s_axil_bready && s_axil_bvalid) begin
                        s_axil_bvalid <= 1'b0;
                        s_axil_awready <= 1'b1;
                        write_state <= WRITE_IDLE;
                    end
                end
                
                default: write_state <= WRITE_IDLE;
            endcase
        end
    end
    
    // 读地址暂存优化
    reg read_from_data_a;
    reg read_from_data_b;
    reg read_from_compare;
    reg read_from_match_flag;
    reg read_address_error;
    
    // 读通道状态机
    always @(posedge clk) begin
        if (rst) begin
            read_state <= READ_IDLE;
            s_axil_arready <= 1'b1;
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= RESP_OKAY;
            read_from_data_a <= 1'b0;
            read_from_data_b <= 1'b0;
            read_from_compare <= 1'b0;
            read_from_match_flag <= 1'b0;
            read_address_error <= 1'b0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    if (s_axil_arvalid && s_axil_arready) begin
                        // 直接解码地址
                        read_from_data_a <= (s_axil_araddr[3:0] == ADDR_DATA_A);
                        read_from_data_b <= (s_axil_araddr[3:0] == ADDR_DATA_B);
                        read_from_compare <= (s_axil_araddr[3:0] == ADDR_COMPARE);
                        read_from_match_flag <= (s_axil_araddr[3:0] == ADDR_MATCH_FLAG);
                        read_address_error <= ~((s_axil_araddr[3:0] == ADDR_DATA_A) || 
                                               (s_axil_araddr[3:0] == ADDR_DATA_B) || 
                                               (s_axil_araddr[3:0] == ADDR_COMPARE) ||
                                               (s_axil_araddr[3:0] == ADDR_MATCH_FLAG));
                        
                        s_axil_arready <= 1'b0;
                        read_state <= READ_DATA;
                    end
                end
                
                READ_DATA: begin
                    s_axil_rvalid <= 1'b1;
                    s_axil_rresp <= read_address_error ? RESP_SLVERR : RESP_OKAY;
                    
                    // 根据解码后的信号读取对应寄存器
                    s_axil_rdata <= 32'b0; // 默认值
                    if (read_from_data_a) s_axil_rdata[7:0] <= data_a;
                    if (read_from_data_b) s_axil_rdata[7:0] <= data_b;
                    if (read_from_compare) s_axil_rdata[7:0] <= compare_data;
                    if (read_from_match_flag) s_axil_rdata[0] <= match_flag;
                    
                    if (s_axil_rready && s_axil_rvalid) begin
                        s_axil_rvalid <= 1'b0;
                        s_axil_arready <= 1'b1;
                        read_state <= READ_IDLE;
                    end
                end
                
                default: read_state <= READ_IDLE;
            endcase
        end
    end
    
    // 优化的比较逻辑 - 将比较分开并使用寄存器存储中间结果
    always @(posedge clk) begin
        if (rst) begin
            match_a <= 1'b0;
            match_b <= 1'b0;
            match_flag <= 1'b0;
        end else begin
            // 单独比较每个数据源，利用硬件并行性
            match_a <= (data_a == compare_data);
            match_b <= (data_b == compare_data);
            // 最终结果的OR计算
            match_flag <= match_a || match_b;
        end
    end

endmodule