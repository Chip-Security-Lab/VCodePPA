//SystemVerilog
module int_ctrl_hybrid #(
    parameter HIGH_PRI = 3
)(
    input clk, rst_n,
    input [7:0] req,
    output reg [2:0] pri_code,
    output reg intr_flag
);
    // Buffered request signals with reduced pipeline stages
    reg [7:0] req_buf;
    wire [3:0] high_req_group, low_req_group;
    
    // Optimized request buffering - single stage is sufficient
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            req_buf <= 8'b0;
        else
            req_buf <= req;
    end
    
    // Split request groups for more efficient priority encoding
    assign high_req_group = req_buf[7:4];
    assign low_req_group = req_buf[3:0];
    
    // High priority group detection - computed once and reused
    wire high_group_active = |high_req_group;
    
    // Optimized priority encoders using parallel comparison
    reg [2:0] pri_code_next;
    always @(*) begin
        if(high_group_active) begin
            casez(high_req_group)
                4'b1???: pri_code_next = 3'h7;
                4'b01??: pri_code_next = 3'h6;
                4'b001?: pri_code_next = 3'h5;
                4'b0001: pri_code_next = 3'h4;
                default: pri_code_next = 3'h0; // Should never happen
            endcase
        end
        else begin
            casez(low_req_group)
                4'b1???: pri_code_next = 3'h0;
                4'b01??: pri_code_next = 3'h1;
                4'b001?: pri_code_next = 3'h2;
                4'b0001: pri_code_next = 3'h3;
                default: pri_code_next = 3'h0; // Default when no requests
            endcase
        end
    end
    
    // Output registers with simplified logic
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            pri_code <= 3'b0;
            intr_flag <= 1'b0;
        end else begin
            pri_code <= pri_code_next;
            intr_flag <= |req_buf;
        end
    end
endmodule