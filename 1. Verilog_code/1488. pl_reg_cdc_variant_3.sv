//SystemVerilog
module pl_reg_cdc #(parameter W=8) (
    input wire src_clk,
    input wire dst_clk,
    input wire src_valid,
    input wire dst_ready,
    input wire [W-1:0] src_data,
    output wire src_ready,
    output wire dst_valid,
    output wire [W-1:0] dst_data
);

    // Source domain registers
    reg [W-1:0] src_data_reg;
    reg src_valid_reg;
    reg src_handshake_reg;
    
    // Pre-synchronization data and valid registers
    reg [W-1:0] pre_sync_data;
    reg pre_sync_valid;
    
    // Synchronization registers (2-FF synchronizer for control signals)
    reg [2:0] dst_sync_valid;
    reg [2:0] src_sync_ack;
    
    // Destination domain registers
    reg dst_valid_reg;
    reg [W-1:0] dst_data_reg;
    
    // Handshake signals after synchronization
    wire dst_domain_valid = dst_sync_valid[2];
    wire src_domain_ack = src_sync_ack[2];
    
    // Source domain data capture
    always @(posedge src_clk) begin
        if (src_valid && src_ready) begin
            src_data_reg <= src_data;
        end
    end
    
    // Source domain valid control
    always @(posedge src_clk) begin
        if (src_valid && src_ready) begin
            src_valid_reg <= 1'b1;
        end else if (src_domain_ack) begin
            src_valid_reg <= 1'b0;
        end
    end
    
    // Pre-synchronization data capture
    always @(posedge src_clk) begin
        if (src_valid_reg && !src_handshake_reg) begin
            pre_sync_data <= src_data_reg;
        end
    end
    
    // Pre-synchronization valid control
    always @(posedge src_clk) begin
        if (src_valid_reg && !src_handshake_reg) begin
            pre_sync_valid <= 1'b1;
        end else if (src_domain_ack) begin
            pre_sync_valid <= 1'b0;
        end
    end
    
    // Handshake detection in source domain
    always @(posedge src_clk) begin
        if (src_valid_reg && !src_handshake_reg && src_domain_ack) begin
            src_handshake_reg <= 1'b1;
        end else if (!src_valid_reg) begin
            src_handshake_reg <= 1'b0;
        end
    end
    
    // Valid signal synchronization (src → dst)
    always @(posedge dst_clk) begin
        dst_sync_valid <= {dst_sync_valid[1:0], pre_sync_valid};
    end
    
    // Acknowledgment synchronization (dst → src)
    always @(posedge src_clk) begin
        src_sync_ack <= {src_sync_ack[1:0], dst_valid_reg && dst_ready};
    end
    
    // Destination domain valid control
    always @(posedge dst_clk) begin
        if (dst_domain_valid && !dst_valid_reg) begin
            dst_valid_reg <= 1'b1;
        end else if (dst_valid_reg && dst_ready) begin
            dst_valid_reg <= 1'b0;
        end
    end
    
    // Destination domain data register
    always @(posedge dst_clk) begin
        if (dst_domain_valid && !dst_valid_reg) begin
            dst_data_reg <= pre_sync_data;
        end
    end
    
    // Output assignments
    assign src_ready = !src_valid_reg || src_domain_ack;
    assign dst_valid = dst_valid_reg;
    assign dst_data = dst_data_reg;

endmodule