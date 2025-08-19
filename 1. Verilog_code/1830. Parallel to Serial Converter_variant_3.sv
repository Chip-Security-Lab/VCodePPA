//SystemVerilog
module parallel2serial #(parameter DATA_WIDTH = 8) (
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  valid_in,
    input  wire [DATA_WIDTH-1:0] parallel_data,
    output wire                  ready,
    output reg                   serial_out,
    output wire                  valid_out
);
    reg [DATA_WIDTH-1:0] shift_reg;
    reg [$clog2(DATA_WIDTH):0] bit_count;
    reg busy;
    
    assign ready = ~busy;
    assign valid_out = (bit_count > 0);
    
    // 定义状态编码
    localparam [1:0] IDLE = 2'b00,
                     LOAD = 2'b01,
                     SHIFT = 2'b10;
    
    // 状态变量
    reg [1:0] state;
    
    always @(posedge clk) begin
        if (rst) begin
            shift_reg <= 0;
            bit_count <= 0;
            serial_out <= 0;
            busy <= 0;
            state <= IDLE;
        end else begin
            if (state == IDLE) begin
                if (valid_in) begin
                    shift_reg <= parallel_data;
                    bit_count <= DATA_WIDTH;
                    busy <= 1;
                    state <= SHIFT;
                end
            end else if (state == SHIFT) begin
                serial_out <= shift_reg[DATA_WIDTH-1];
                shift_reg <= {shift_reg[DATA_WIDTH-2:0], 1'b0};
                bit_count <= bit_count - 1;
                
                if (bit_count == 1) begin
                    busy <= 0;
                    state <= IDLE;
                end
            end else begin
                state <= IDLE;
            end
        end
    end
endmodule