//SystemVerilog
module int_ctrl_hybrid #(
    parameter HIGH_PRI = 3
)(
    input clk, rst_n,
    input [7:0] req,
    output reg [2:0] pri_code,
    output reg intr_flag
);
    // Pre-registered request signals to reduce input-to-register path
    reg [7:0] req_reg;
    
    // Internal signals for priority encoding
    reg high_req;
    reg [2:0] high_pri_code;
    reg [2:0] low_pri_code;
    
    // Register input requests to improve timing
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            req_reg <= 8'b0;
        end else begin
            req_reg <= req;
        end
    end
    
    // Pre-compute priority logic in parallel with registered inputs
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            high_req <= 1'b0;
            high_pri_code <= 3'b0;
            low_pri_code <= 3'b0;
        end else begin
            high_req <= |req_reg[7:4];
            
            // High priority encoding with registered inputs
            high_pri_code <= req_reg[7] ? 3'h7 :
                            req_reg[6] ? 3'h6 :
                            req_reg[5] ? 3'h5 : 3'h4;
            
            // Low priority encoding with registered inputs
            low_pri_code <= req_reg[0] ? 3'h0 :
                           req_reg[1] ? 3'h1 :
                           req_reg[2] ? 3'h2 : 3'h3;
        end
    end
    
    // Final output stage with simple mux logic
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            pri_code <= 3'b0;
            intr_flag <= 1'b0;
        end else begin
            pri_code <= high_req ? high_pri_code : low_pri_code;
            intr_flag <= |req_reg;
        end
    end
endmodule