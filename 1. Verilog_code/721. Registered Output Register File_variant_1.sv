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

    // Pipeline stage 1 - Address decode and read enable
    reg [ADDR_WIDTH-1:0] raddr_stage1;
    reg re_stage1;

    // Pipeline stage 2 - Data read
    reg [WIDTH-1:0] rdata_stage2;
    reg re_stage2;

    // Pipeline stage 1
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            raddr_stage1 <= {ADDR_WIDTH{1'b0}};
            re_stage1 <= 1'b0;
        end
        else begin
            raddr_stage1 <= raddr;
            re_stage1 <= re;
        end
    end

    // Pipeline stage 2
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            rdata_stage2 <= {WIDTH{1'b0}};
            re_stage2 <= 1'b0;
        end
        else if (re_stage1) begin
            rdata_stage2 <= registers[raddr_stage1];
            re_stage2 <= re_stage1;
        end
    end

    // Output stage
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            rdata <= {WIDTH{1'b0}};
            rvalid <= 1'b0;
        end
        else begin
            rdata <= rdata_stage2;
            rvalid <= re_stage2;
        end
    end

    // Write operation
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            integer i;
            for (i = 0; i < DEPTH; i = i + 1) begin
                registers[i] <= {WIDTH{1'b0}};
            end
        end
        else if (we) begin
            registers[waddr] <= wdata;
        end
    end

endmodule