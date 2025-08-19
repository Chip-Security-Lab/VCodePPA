//SystemVerilog
module mem_arbiter(
    input wire clk, rst,
    input wire req1, req2, req3,
    input wire [7:0] addr1, addr2, addr3,
    input wire [7:0] wdata1, wdata2, wdata3,
    input wire wen1, wen2, wen3,
    output reg [7:0] addr_out, wdata_out,
    output reg wen_out, ack1, ack2, ack3
);
    localparam IDLE=3'd0, GRANT1=3'd1, GRANT2=3'd2, GRANT3=3'd3;
    reg [2:0] state, next;
    reg req1_d, req2_d, req3_d;
    wire req1_edge, req2_edge, req3_edge;
    
    // Edge detection logic
    assign req1_edge = req1 && !req1_d;
    assign req2_edge = req2 && !req2_d;
    assign req3_edge = req3 && !req3_d;
    
    // State and request registers
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            req1_d <= 1'b0;
            req2_d <= 1'b0;
            req3_d <= 1'b0;
        end else begin
            state <= next;
            req1_d <= req1;
            req2_d <= req2;
            req3_d <= req3;
        end
    end
    
    // Priority encoder for next state
    always @(*) begin
        next = IDLE;
        
        case (state)
            IDLE: begin
                if (req1_edge) next = GRANT1;
                else if (req2_edge) next = GRANT2;
                else if (req3_edge) next = GRANT3;
            end
            GRANT1: begin
                if (req1) next = GRANT1;
                else if (req2_edge) next = GRANT2;
                else if (req3_edge) next = GRANT3;
            end
            GRANT2: begin
                if (req2) next = GRANT2;
                else if (req3_edge) next = GRANT3;
                else if (req1_edge) next = GRANT1;
            end
            GRANT3: begin
                if (req3) next = GRANT3;
                else if (req1_edge) next = GRANT1;
                else if (req2_edge) next = GRANT2;
            end
            default: next = IDLE;
        endcase
    end
    
    // Output logic
    always @(*) begin
        // Default outputs
        ack1 = 1'b0; ack2 = 1'b0; ack3 = 1'b0;
        addr_out = 8'd0; wdata_out = 8'd0; wen_out = 1'b0;
        
        // Set outputs based on current state
        case (state)
            GRANT1: begin
                ack1 = 1'b1;
                addr_out = addr1;
                wdata_out = wdata1;
                wen_out = wen1;
            end
            GRANT2: begin
                ack2 = 1'b1;
                addr_out = addr2;
                wdata_out = wdata2;
                wen_out = wen2;
            end
            GRANT3: begin
                ack3 = 1'b1;
                addr_out = addr3;
                wdata_out = wdata3;
                wen_out = wen3;
            end
        endcase
    end
endmodule