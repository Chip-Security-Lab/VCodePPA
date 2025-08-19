//SystemVerilog
module registered_output_regfile #(
    parameter WIDTH = 32,
    parameter ADDR_WIDTH = 5,
    parameter DEPTH = 2**ADDR_WIDTH
)(
    input  wire                   clock,
    input  wire                   resetn,
    input  wire                   we,
    input  wire [ADDR_WIDTH-1:0]  waddr,
    input  wire [WIDTH-1:0]       wdata,
    input  wire                   re,
    input  wire [ADDR_WIDTH-1:0]  raddr,
    output reg  [WIDTH-1:0]       rdata,
    output reg                    rvalid
);

    // Memory array
    reg [WIDTH-1:0] registers [0:DEPTH-1];
    
    // Pipeline registers for read path
    reg [WIDTH-1:0] rdata_pipe;
    reg [ADDR_WIDTH-1:0] raddr_pipe;
    reg re_pipe;

    // Combined always block for address control, data read, and output stage
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            integer i;
            raddr_pipe <= {ADDR_WIDTH{1'b0}};
            re_pipe <= 1'b0;
            rdata_pipe <= {WIDTH{1'b0}};
            rdata <= {WIDTH{1'b0}};
            rvalid <= 1'b0;
            for (i = 0; i < DEPTH; i = i + 1) begin
                registers[i] <= {WIDTH{1'b0}};
            end
        end
        else begin
            raddr_pipe <= raddr;
            re_pipe <= re;
            if (re_pipe) begin
                rdata_pipe <= registers[raddr_pipe];
            end
            rdata <= rdata_pipe;
            rvalid <= re_pipe;
            if (we) begin
                registers[waddr] <= wdata;
            end
        end
    end

endmodule