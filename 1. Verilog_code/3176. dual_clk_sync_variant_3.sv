//SystemVerilog
module dual_clk_sync(
    input src_clk,
    input dst_clk,
    input rst_n,
    input pulse_in,
    output reg pulse_out
);
    reg toggle_ff;
    reg [1:0] sync_ff;
    reg [1:0] state;
    
    // 源时钟域
    always @(posedge src_clk or negedge rst_n) begin
        if (!rst_n) begin
            toggle_ff <= 1'b0;
            state <= 2'b00;
        end else begin
            case(state)
                2'b00: begin
                    if (pulse_in) begin
                        toggle_ff <= ~toggle_ff;
                        state <= 2'b01;
                    end
                end
                2'b01: begin
                    state <= 2'b00;
                end
                default: state <= 2'b00;
            endcase
        end
    end
    
    // 目标时钟域
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff <= 2'b00;
            pulse_out <= 1'b0;
        end else begin
            case(sync_ff)
                2'b00: begin
                    sync_ff <= {sync_ff[0], toggle_ff};
                    pulse_out <= 1'b0;
                end
                2'b01: begin
                    sync_ff <= {sync_ff[0], toggle_ff};
                    pulse_out <= 1'b1;
                end
                2'b10: begin
                    sync_ff <= {sync_ff[0], toggle_ff};
                    pulse_out <= 1'b1;
                end
                2'b11: begin
                    sync_ff <= {sync_ff[0], toggle_ff};
                    pulse_out <= 1'b0;
                end
            endcase
        end
    end
endmodule