//SystemVerilog
module basic_regfile #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5,
    parameter DEPTH = 2**ADDR_WIDTH
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   we,
    input  wire [ADDR_WIDTH-1:0]  addr,
    input  wire [DATA_WIDTH-1:0]  wdata,
    output wire [DATA_WIDTH-1:0]  rdata
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH:0]   state;
    reg [ADDR_WIDTH-1:0] counter;
    
    localparam IDLE = 0;
    localparam RESET = 1;
    localparam HOLD = 2;
    
    assign rdata = mem[addr];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= RESET;
            counter <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (!we) begin
                        state <= RESET;
                        counter <= 0;
                    end else if (we) begin
                        mem[addr] <= wdata;
                    end
                end
                
                RESET: begin
                    if (counter < DEPTH) begin
                        mem[counter] <= {DATA_WIDTH{1'b0}};
                        counter <= counter + 1;
                    end else begin
                        state <= IDLE;
                    end
                end
                
                HOLD: begin
                    if (counter < DEPTH) begin
                        mem[counter] <= mem[counter];
                        counter <= counter + 1;
                    end else begin
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    always @(*) begin
        if (!rst_n) begin
            state = RESET;
        end else if (!we) begin
            state = RESET;
        end else if (we) begin
            state = IDLE;
        end else begin
            state = HOLD;
        end
    end
endmodule