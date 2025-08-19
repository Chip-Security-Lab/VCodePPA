//SystemVerilog
module int_ctrl_threshold #(
    parameter WIDTH = 6,
    parameter THRESHOLD = 3
)(
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] req,
    output reg valid,
    output reg [2:0] code
);
    // Stage 1: Request masking - isolate values >= THRESHOLD
    reg [WIDTH-1:0] masked_req_stage1;
    wire [WIDTH-1:0] mask = ~((1 << THRESHOLD) - 1);
    
    // Stage 2: Priority encoding registers
    reg valid_stage2;
    reg [2:0] code_stage2;
    
    // Stage 1: Mask the requests and register
    always @(posedge clk) begin
        if (rst) begin
            masked_req_stage1 <= {WIDTH{1'b0}};
        end else begin
            masked_req_stage1 <= req & mask;
        end
    end
    
    // Stage 2: Priority encoding
    always @(posedge clk) begin
        if (rst) begin
            valid_stage2 <= 1'b0;
            code_stage2 <= 3'b0;
        end else begin
            valid_stage2 <= |masked_req_stage1;
            code_stage2 <= priority_encoder(masked_req_stage1);
        end
    end
    
    // Output stage
    always @(posedge clk) begin
        if (rst) begin
            valid <= 1'b0;
            code <= 3'b0;
        end else begin
            valid <= valid_stage2;
            code <= code_stage2;
        end
    end
    
    // Priority encoder function with flattened if-else structure
    function [2:0] priority_encoder;
        input [WIDTH-1:0] data_in;
        begin
            priority_encoder = 3'b0;
            
            if (WIDTH > 5 && data_in[5]) priority_encoder = 3'd5;
            else if (WIDTH > 4 && data_in[4]) priority_encoder = 3'd4;
            else if (WIDTH > 3 && data_in[3]) priority_encoder = 3'd3;
            else if (WIDTH > 2 && data_in[2]) priority_encoder = 3'd2;
            else if (WIDTH > 1 && data_in[1]) priority_encoder = 3'd1;
            else if (WIDTH > 0 && data_in[0]) priority_encoder = 3'd0;
        end
    endfunction

endmodule