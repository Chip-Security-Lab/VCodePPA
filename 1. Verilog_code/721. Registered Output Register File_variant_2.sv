//SystemVerilog
// Top level module
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

    // Internal signals
    wire [WIDTH-1:0] rdata_stage1;
    wire [ADDR_WIDTH-1:0] raddr_stage1;
    wire re_stage1;
    wire [WIDTH-1:0] rdata_stage2;
    wire re_stage2;
    wire [WIDTH-1:0] rdata_stage3;
    wire re_stage3;

    // Memory array module
    memory_array #(
        .WIDTH(WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DEPTH(DEPTH)
    ) mem_inst (
        .clock(clock),
        .resetn(resetn),
        .we(we),
        .waddr(waddr),
        .wdata(wdata),
        .raddr(raddr),
        .rdata(rdata_stage1)
    );

    // Pipeline stage 1 module
    pipeline_stage1 #(
        .WIDTH(WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) stage1_inst (
        .clock(clock),
        .resetn(resetn),
        .re(re),
        .raddr(raddr),
        .rdata_in(rdata_stage1),
        .rdata_out(rdata_stage2),
        .raddr_out(raddr_stage1),
        .re_out(re_stage1)
    );

    // Pipeline stage 2 module
    pipeline_stage2 #(
        .WIDTH(WIDTH)
    ) stage2_inst (
        .clock(clock),
        .resetn(resetn),
        .re_in(re_stage1),
        .rdata_in(rdata_stage2),
        .rdata_out(rdata_stage3),
        .re_out(re_stage2)
    );

    // Pipeline stage 3 module
    pipeline_stage3 #(
        .WIDTH(WIDTH)
    ) stage3_inst (
        .clock(clock),
        .resetn(resetn),
        .re_in(re_stage2),
        .rdata_in(rdata_stage3),
        .rdata_out(rdata),
        .re_out(re_stage3)
    );

    // Output valid generation
    always @(posedge clock or negedge resetn) begin
        if (!resetn)
            rvalid <= 1'b0;
        else
            rvalid <= re_stage3;
    end

endmodule

// Memory array module
module memory_array #(
    parameter WIDTH = 32,
    parameter ADDR_WIDTH = 5,
    parameter DEPTH = 2**ADDR_WIDTH
)(
    input  wire                   clock,
    input  wire                   resetn,
    input  wire                   we,
    input  wire [ADDR_WIDTH-1:0]  waddr,
    input  wire [WIDTH-1:0]       wdata,
    input  wire [ADDR_WIDTH-1:0]  raddr,
    output reg  [WIDTH-1:0]       rdata
);

    reg [WIDTH-1:0] registers [0:DEPTH-1];
    integer i;

    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            for (i = 0; i < DEPTH; i = i + 1)
                registers[i] <= {WIDTH{1'b0}};
        end
        else if (we)
            registers[waddr] <= wdata;
    end

    always @(posedge clock) begin
        rdata <= registers[raddr];
    end

endmodule

// Pipeline stage 1 module
module pipeline_stage1 #(
    parameter WIDTH = 32,
    parameter ADDR_WIDTH = 5
)(
    input  wire                   clock,
    input  wire                   resetn,
    input  wire                   re,
    input  wire [ADDR_WIDTH-1:0]  raddr,
    input  wire [WIDTH-1:0]       rdata_in,
    output reg  [WIDTH-1:0]       rdata_out,
    output reg  [ADDR_WIDTH-1:0]  raddr_out,
    output reg                    re_out
);

    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            rdata_out <= {WIDTH{1'b0}};
            raddr_out <= {ADDR_WIDTH{1'b0}};
            re_out <= 1'b0;
        end
        else begin
            rdata_out <= rdata_in;
            raddr_out <= raddr;
            re_out <= re;
        end
    end

endmodule

// Pipeline stage 2 module
module pipeline_stage2 #(
    parameter WIDTH = 32
)(
    input  wire                   clock,
    input  wire                   resetn,
    input  wire                   re_in,
    input  wire [WIDTH-1:0]       rdata_in,
    output reg  [WIDTH-1:0]       rdata_out,
    output reg                    re_out
);

    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            rdata_out <= {WIDTH{1'b0}};
            re_out <= 1'b0;
        end
        else begin
            rdata_out <= rdata_in;
            re_out <= re_in;
        end
    end

endmodule

// Pipeline stage 3 module
module pipeline_stage3 #(
    parameter WIDTH = 32
)(
    input  wire                   clock,
    input  wire                   resetn,
    input  wire                   re_in,
    input  wire [WIDTH-1:0]       rdata_in,
    output reg  [WIDTH-1:0]       rdata_out,
    output reg                    re_out
);

    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            rdata_out <= {WIDTH{1'b0}};
            re_out <= 1'b0;
        end
        else begin
            rdata_out <= rdata_in;
            re_out <= re_in;
        end
    end

endmodule