//SystemVerilog
// Priority encoder submodule
module priority_encoder #(
    parameter WIDTH = 4,
    parameter GRANT_WIDTH = $clog2(WIDTH)
)(
    input wire [WIDTH-1:0] req,
    output reg [GRANT_WIDTH-1:0] grant
);

    always @* begin
        grant = {GRANT_WIDTH{1'b0}};
        for (integer i = 0; i < WIDTH; i = i + 1) begin
            if (req[i]) begin
                grant = i[GRANT_WIDTH-1:0];
            end
        end
    end

endmodule

// Register module for input/output
module reg_module #(
    parameter WIDTH = 4
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= {WIDTH{1'b0}};
        end else begin
            q <= d;
        end
    end

endmodule

// Top-level priority decoder module
module decoder_priority #(
    parameter WIDTH = 4,
    parameter GRANT_WIDTH = $clog2(WIDTH)
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] req,
    output wire [GRANT_WIDTH-1:0] grant
);

    // Internal signals
    wire [WIDTH-1:0] req_reg;
    wire [GRANT_WIDTH-1:0] grant_next;
    
    // Input register instance
    reg_module #(
        .WIDTH(WIDTH)
    ) req_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .d(req),
        .q(req_reg)
    );
    
    // Priority encoder instance
    priority_encoder #(
        .WIDTH(WIDTH),
        .GRANT_WIDTH(GRANT_WIDTH)
    ) priority_encoder_inst (
        .req(req_reg),
        .grant(grant_next)
    );
    
    // Output register instance
    reg_module #(
        .WIDTH(GRANT_WIDTH)
    ) grant_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .d(grant_next),
        .q(grant)
    );

endmodule