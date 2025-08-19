//SystemVerilog
module param_sync_reg #(parameter WIDTH=4) (
    input                  clk1,
    input                  clk2,
    input                  rst,
    input  [WIDTH-1:0]     din,
    output reg [WIDTH-1:0] dout
);

    // Stage 1: Capture input data on clk1 domain
    reg [WIDTH-1:0] stage1_data;
    // Stage 2: Pipeline register to break long path, still on clk1 domain
    reg [WIDTH-1:0] stage2_data;
    // Stage 3: Synchronize to clk2 domain (cross domain stage)
    reg [WIDTH-1:0] sync_stage1;

    //==============================================================
    // Always block for reset and input sampling (clk1 domain)
    //==============================================================
    // Function: Asynchronous reset and sampling input din to stage1_data
    always @(posedge clk1 or posedge rst) begin
        if (rst)
            stage1_data <= {WIDTH{1'b0}};
        else
            stage1_data <= din;
    end

    //==============================================================
    // Always block for pipeline register (clk1 domain)
    //==============================================================
    // Function: Asynchronous reset and pipeline stage1_data to stage2_data
    always @(posedge clk1 or posedge rst) begin
        if (rst)
            stage2_data <= {WIDTH{1'b0}};
        else
            stage2_data <= stage1_data;
    end

    //==============================================================
    // Always block for clock domain crossing (clk2 domain)
    //==============================================================
    // Function: Asynchronous reset and synchronizing stage2_data to clk2 domain
    always @(posedge clk2 or posedge rst) begin
        if (rst)
            sync_stage1 <= {WIDTH{1'b0}};
        else
            sync_stage1 <= stage2_data;
    end

    //==============================================================
    // Always block for output register (clk2 domain)
    //==============================================================
    // Function: Asynchronous reset and output register assignment
    always @(posedge clk2 or posedge rst) begin
        if (rst)
            dout <= {WIDTH{1'b0}};
        else
            dout <= sync_stage1;
    end

endmodule