//SystemVerilog
module axi_stream_adapter #(
    parameter DW = 32
)(
    input  wire            clk,
    input  wire            resetn,
    input  wire [DW-1:0]   tdata,
    input  wire            tvalid,
    output reg             tready,
    output reg  [DW-1:0]   rdata,
    output reg             rvalid
);

    // 状态定义 - 使用单热编码以改善时序性能
    localparam [1:0] IDLE = 2'b01;
    localparam [1:0] BUSY = 2'b10;
    reg [1:0] state;
    
    // 将tready转换为组合逻辑以减少路径延迟
    wire next_tready;
    assign next_tready = (state == BUSY) || ((state == IDLE) && !tvalid);
    
    // 状态和输出寄存器更新
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            state  <= IDLE;
            tready <= 1'b1;
            rvalid <= 1'b0;
            rdata  <= {DW{1'b0}};
        end else begin
            // 优化状态转换逻辑
            case (state)
                IDLE: begin
                    if (tvalid) begin
                        state  <= BUSY;
                        rdata  <= tdata;
                        rvalid <= 1'b1;
                    end else begin
                        rvalid <= 1'b0;
                    end
                end
                
                BUSY: begin
                    state  <= IDLE;
                    rvalid <= 1'b0;
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
            
            // 更新tready
            tready <= next_tready;
        end
    end
endmodule