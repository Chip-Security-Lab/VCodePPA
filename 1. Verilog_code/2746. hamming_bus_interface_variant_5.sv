//SystemVerilog
module hamming_bus_interface(
    input clk, rst, cs, we,
    input [3:0] addr,
    input [7:0] wdata,
    output reg [7:0] rdata,
    output reg ready
);
    reg [6:0] encoded;
    reg [3:0] status;
    
    // Ready信号控制逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ready <= 1'b0;
        end else if (cs) begin
            ready <= 1'b1;
        end else begin
            ready <= 1'b0;
        end
    end
    
    // 编码逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded <= 7'b0;
            status[0] <= 1'b0;
        end else if (cs && we && addr == 4'h0) begin
            encoded[0] <= wdata[0] ^ wdata[1] ^ wdata[3];
            encoded[1] <= wdata[0] ^ wdata[2] ^ wdata[3];
            encoded[2] <= wdata[0];
            encoded[3] <= wdata[1] ^ wdata[2] ^ wdata[3];
            encoded[4] <= wdata[1];
            encoded[5] <= wdata[2];
            encoded[6] <= wdata[3];
            status[0] <= 1'b1; // Encoding done
        end
    end
    
    // 状态寄存器控制逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            status[3:1] <= 3'b0;
        end else if (cs && we && addr == 4'h4) begin
            status[3:1] <= wdata[3:1];
        end
    end
    
    // 读数据逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rdata <= 8'b0;
        end else if (cs && !we) begin
            case (addr)
                4'h0: rdata <= {1'b0, encoded}; // Read encoded data
                4'h4: rdata <= {4'b0, status};  // Read status
                default: rdata <= 8'b0;
            endcase
        end
    end
    
endmodule