//SystemVerilog
module two_stage_decoder (
    input clk,
    input rst_n,
    input [3:0] address,
    input req,
    output reg ack,
    output reg [15:0] select
);

    // Internal signals
    wire [3:0] stage1_out;
    reg [3:0] address_reg;
    reg req_reg;
    reg [3:0] stage2_out;
    
    // Input register stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            address_reg <= 4'b0;
            req_reg <= 1'b0;
        end else begin
            address_reg <= address;
            req_reg <= req;
        end
    end
    
    // First stage decoder - decodes top 2 bits
    assign stage1_out = (4'b0001 << address_reg[3:2]);
    
    // Second stage decoder - decodes bottom 2 bits
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_out <= 4'b0;
        end else if (req_reg) begin
            case (address_reg[1:0])
                2'b00: stage2_out <= {3'b000, stage1_out[0]};
                2'b01: stage2_out <= {3'b000, stage1_out[1]};
                2'b10: stage2_out <= {3'b000, stage1_out[2]};
                2'b11: stage2_out <= {3'b000, stage1_out[3]};
                default: stage2_out <= 4'b0;
            endcase
        end else begin
            stage2_out <= 4'b0;
        end
    end
    
    // Output stage - generates final select and ack signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            select <= 16'b0;
            ack <= 1'b0;
        end else if (req_reg) begin
            select[3:0]   <= stage2_out;
            select[7:4]   <= stage2_out;
            select[11:8]  <= stage2_out;
            select[15:12] <= stage2_out;
            ack <= 1'b1;
        end else begin
            select <= 16'b0;
            ack <= 1'b0;
        end
    end

endmodule