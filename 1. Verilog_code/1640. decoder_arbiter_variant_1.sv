//SystemVerilog
module decoder_arbiter #(
    parameter NUM_MASTERS = 2
) (
    input wire clk,
    input wire rst_n,
    input wire [NUM_MASTERS-1:0] req,
    output reg [NUM_MASTERS-1:0] grant
);

    // Pipeline stage 1: Request processing
    reg [NUM_MASTERS-1:0] req_ff;
    reg [NUM_MASTERS-1:0] req_inv_ff;
    
    // Pipeline stage 2: Priority encoding
    reg [NUM_MASTERS-1:0] grant_ff;
    
    // Stage 1: Register input requests and compute inverse
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_ff <= {NUM_MASTERS{1'b0}};
            req_inv_ff <= {NUM_MASTERS{1'b0}};
        end else begin
            req_ff <= req;
            req_inv_ff <= ~req;
        end
    end
    
    // Stage 2: Priority encoding with registered output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_ff <= {NUM_MASTERS{1'b0}};
        end else begin
            grant_ff <= req_ff & ~req_inv_ff;
        end
    end
    
    // Output assignment
    assign grant = grant_ff;

endmodule