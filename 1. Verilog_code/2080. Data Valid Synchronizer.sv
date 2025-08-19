module data_valid_sync #(parameter WIDTH = 32) (
    input wire src_clk, dst_clk, reset_n,
    input wire [WIDTH-1:0] data_in,
    input wire valid_in,
    output wire ready_out,
    output reg [WIDTH-1:0] data_out,
    output reg valid_out,
    input wire ready_in
);
    reg req_src, ack_src;
    reg req_meta, req_dst;
    reg ack_meta, ack_dst;
    reg [WIDTH-1:0] data_reg;
    
    // Source clock domain handshaking
    always @(posedge src_clk or negedge reset_n) begin
        if (!reset_n) begin
            req_src <= 1'b0;
            ack_src <= 1'b0;
            ack_meta <= 1'b0;
            data_reg <= {WIDTH{1'b0}};
        end else begin
            ack_meta <= ack_dst;
            ack_src <= ack_meta;
            
            if (valid_in && !req_src && (ack_src == req_src)) begin
                data_reg <= data_in;
                req_src <= ~req_src;
            end
        end
    end
    
    // Destination clock domain handshaking
    always @(posedge dst_clk or negedge reset_n) begin
        if (!reset_n) begin
            req_meta <= 1'b0;
            req_dst <= 1'b0;
            ack_dst <= 1'b0;
            valid_out <= 1'b0;
            data_out <= {WIDTH{1'b0}};
        end else begin
            req_meta <= req_src;
            req_dst <= req_meta;
            
            if (req_dst != ack_dst) begin
                if (ready_in) begin
                    data_out <= data_reg;
                    valid_out <= 1'b1;
                    ack_dst <= req_dst;
                end
            end else begin
                valid_out <= 1'b0;
            end
        end
    end
    
    assign ready_out = (req_src == ack_src);
endmodule