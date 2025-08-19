//SystemVerilog
module int_ctrl_sync_fixed #(
    parameter WIDTH = 8
)(
    input clk, rst_n, en,
    input [WIDTH-1:0] req,
    output reg [$clog2(WIDTH)-1:0] grant
);
    reg [WIDTH-1:0] req_r;
    wire [$clog2(WIDTH)-1:0] priority_out;
    
    // Register req input to improve timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            req_r <= {WIDTH{1'b0}};
        else if (en)
            req_r <= req;
    end
    
    // Priority encoder logic in continuous assignment
    generate
        if (WIDTH == 2) begin : gen_width2
            assign priority_out = req_r[1] ? 1'b1 : 1'b0;
        end
        else if (WIDTH <= 4) begin : gen_width4
            assign priority_out = req_r[3] ? 2'd3 :
                                req_r[2] ? 2'd2 :
                                req_r[1] ? 2'd1 : 2'd0;
        end
        else if (WIDTH <= 8) begin : gen_width8
            assign priority_out = req_r[7] ? 3'd7 :
                                req_r[6] ? 3'd6 :
                                req_r[5] ? 3'd5 :
                                req_r[4] ? 3'd4 :
                                req_r[3] ? 3'd3 :
                                req_r[2] ? 3'd2 :
                                req_r[1] ? 3'd1 : 3'd0;
        end
        else if (WIDTH <= 16) begin : gen_width16
            wire [1:0] block_pri;
            wire [3:0] block_sel;
            wire [3:0] pri_in_block;
            
            assign block_sel[3] = |req_r[15:12];
            assign block_sel[2] = |req_r[11:8];
            assign block_sel[1] = |req_r[7:4];
            assign block_sel[0] = |req_r[3:0];
            
            assign block_pri = block_sel[3] ? 2'd3 :
                              block_sel[2] ? 2'd2 :
                              block_sel[1] ? 2'd1 : 2'd0;
            
            assign pri_in_block = (block_pri == 2'd3) ? 
                                  (req_r[15] ? 4'd3 : req_r[14] ? 4'd2 : req_r[13] ? 4'd1 : 4'd0) :
                                 (block_pri == 2'd2) ?
                                  (req_r[11] ? 4'd3 : req_r[10] ? 4'd2 : req_r[9] ? 4'd1 : 4'd0) :
                                 (block_pri == 2'd1) ?
                                  (req_r[7] ? 4'd3 : req_r[6] ? 4'd2 : req_r[5] ? 4'd1 : 4'd0) :
                                  (req_r[3] ? 4'd3 : req_r[2] ? 4'd2 : req_r[1] ? 4'd1 : 4'd0);
            
            assign priority_out = {block_pri, pri_in_block[1:0]};
        end
        else begin : gen_default
            // For larger widths, use a more efficient approach
            // with hierarchical priority encoding
            integer j;
            reg [$clog2(WIDTH)-1:0] pri_temp;
            
            always @(*) begin
                pri_temp = {$clog2(WIDTH){1'b0}};
                for (j = 0; j < WIDTH; j = j + 1) begin
                    if (req_r[j]) pri_temp = j[$clog2(WIDTH)-1:0];
                end
            end
            
            assign priority_out = pri_temp;
        end
    endgenerate
    
    // Register output for better timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            grant <= {$clog2(WIDTH){1'b0}};
        else if (en)
            grant <= priority_out;
    end
endmodule