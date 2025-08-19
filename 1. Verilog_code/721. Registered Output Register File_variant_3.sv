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
    
    // Pipeline stage 1 signals
    reg [ADDR_WIDTH-1:0] raddr_stage1;
    reg re_stage1;
    reg [WIDTH-1:0] rdata_stage1;
    reg rvalid_stage1;
    
    // Pipeline stage 2 signals
    reg [WIDTH-1:0] rdata_stage2;
    reg rvalid_stage2;
    
    // Stage 1: Address and control signal registration
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            raddr_stage1 <= {ADDR_WIDTH{1'b0}};
            re_stage1 <= 1'b0;
            rvalid_stage1 <= 1'b0;
        end else begin
            raddr_stage1 <= raddr;
            re_stage1 <= re;
            rvalid_stage1 <= re;
        end
    end
    
    // Stage 1: Memory read
    always @(posedge clock) begin
        if (re_stage1) begin
            rdata_stage1 <= registers[raddr_stage1];
        end
    end
    
    // Stage 2: Output registration
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            rdata_stage2 <= {WIDTH{1'b0}};
            rvalid_stage2 <= 1'b0;
        end else begin
            rdata_stage2 <= rdata_stage1;
            rvalid_stage2 <= rvalid_stage1;
        end
    end
    
    // Final output assignment
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            rdata <= {WIDTH{1'b0}};
            rvalid <= 1'b0;
        end else begin
            rdata <= rdata_stage2;
            rvalid <= rvalid_stage2;
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