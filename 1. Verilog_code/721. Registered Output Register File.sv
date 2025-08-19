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
    
    // Registered read operation
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            rdata <= {WIDTH{1'b0}};
            rvalid <= 1'b0;
        end
        else if (re) begin
            rdata <= registers[raddr];
            rvalid <= 1'b1;
        end
        else begin
            rvalid <= 1'b0;
        end
    end
    
    // Write operation
    integer i;
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                registers[i] <= {WIDTH{1'b0}};
            end
        end
        else if (we) begin
            registers[waddr] <= wdata;
        end
    end
endmodule